# Rails Backend: API Design

JSON responses, serialization, pagination, versioning, and webhook patterns.

---

## Philosophy

The application is primarily Turbo/Hotwire, but controllers respond to JSON where needed. The same domain model methods serve both formats — no separate API layer.

```ruby
def create
  @card.gild

  respond_to do |format|
    format.turbo_stream { render_card_replacement }
    format.json { head :no_content }
  end
end
```

---

## RESTful URL Design

State changes are modeled as resources, never custom actions:

```
POST   /:account_id/boards/:board_id/cards/:card_id/closure    → close card
DELETE /:account_id/boards/:board_id/cards/:card_id/closure    → reopen card
POST   /:account_id/boards/:board_id/cards/:card_id/goldness   → gild card
POST   /:account_id/boards/:board_id/cards/:card_id/assignments → assign user
```

The `{account_id}` path segment is the multi-tenancy key — middleware extracts it to set `Current.account`.

---

## Standard JSON Response Patterns

```ruby
format.json { head :no_content }                                          # Success, no body
format.json { render json: @card }                                        # Success with resource
format.json { render json: @card, status: :created, location: @card }    # Created
format.json { render json: @card.errors, status: :unprocessable_entity } # Validation failure
format.json { head :forbidden }                                           # Not authorized
```

---

## Serialization

Keep serialization out of models. Use a dedicated serializer object for complex shapes:

```ruby
class CardSerializer
  def initialize(card)
    @card = card
  end

  def as_json
    {
      id: @card.number,      # Always expose number as public ID, never database id
      title: @card.title,
      closed: @card.closed?,
      golden: @card.golden?,
      creator: { id: @card.creator.id, name: @card.creator.name }
    }
  end
end

render json: CardSerializer.new(@card).as_json
```

**Always expose `number` as the public card identifier, not `id`.**

---

## Pagination in API Responses

```ruby
def index
  set_page_and_extract_portion_from Current.account.cards.active.ordered

  respond_to do |format|
    format.json do
      render json: {
        cards: @page.records.map { |c| CardSerializer.new(c).as_json },
        meta: {
          page: @page.number,
          last_page: @page.last?,
          next_page: @page.last? ? nil : @page.next_param,
          total: @page.recordset.records_count
        }
      }
    end
  end
end
```

For large datasets (100k+ rows), use cursor-based pagination:

```ruby
set_page_and_extract_portion_from Event.all, ordered_by: { created_at: :desc, id: :desc }
```

---

## Versioning

Namespace routes and controllers when versioning is needed:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :boards do
      resources :cards
    end
  end
end
```

Controllers in `app/controllers/api/v1/` reuse the same domain model methods. Only serialization and routing differ between versions.

---

## Webhook Events

Webhooks are driven by the event system. Events carry a `particulars` JSON hash with action-specific context:

```ruby
event.action      # => "card_board_changed"
event.eventable   # => the Card record
event.particulars # => { "old_board" => "Project A", "new_board" => "Project B" }
```

Delivery is handled by `Webhook::DeliveryJob` — decoupled from request handling via `after_create_commit` on the Event model.
