# Rails Backend: Controllers

HTTP boundary conventions — thin controllers, RESTful resource modeling, concerns, pagination.

---

## Thin Controllers

Controllers have exactly 3 responsibilities: **setup, call model, respond.** No business logic.

```ruby
class Cards::GoldnessesController < ApplicationController
  include CardScoped  # Sets @card and @board via before_action

  def create
    @card.gild         # Single model method call

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.ungild
    respond_to { |f| f.turbo_stream { render_card_replacement } }
  end
end
```

That's the entire controller. Must not contain business logic, build complex queries, or directly manipulate multiple models.

---

## RESTful Resource Nesting

Model every state change as a resource. Never add custom action methods.

```ruby
# Bad: custom actions
resources :cards do
  post :close
  post :gild
end

# Good: each state change is its own resource
resources :cards do
  scope module: :cards do
    resource :closure   # POST creates (close), DELETE destroys (reopen)
    resource :goldness  # POST creates (gild), DELETE destroys (ungild)
    resource :pin
    resource :watch
    resources :assignments
    resources :comments
  end
end
```

**Rule of thumb**: If the action creates, updates, or destroys something — that "something" is the resource.
- Close card → creates `Closure`
- Gild card → creates `Goldness`
- Assign user → creates `Assignment`

---

## Controller Concerns

Extract repeated `before_action` patterns:

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      # Cards found by :number (user-facing ID), scoped to accessible cards
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board = @board = @card.board

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        [@card, :card_container],
        partial: "cards/container",
        method: :morph,
        locals: { card: @card.reload }
      )
    end
end

module BoardScoped
  extend ActiveSupport::Concern
  included do
    before_action :set_board
  end
  private
    def set_board = @board = Current.user.boards.find(params[:board_id])
    def ensure_admin = head(:forbidden) unless Current.user.can_administer_board?(@board)
end
```

Create a controller concern when 3+ controllers share the same `before_action` or resource loading.

---

## Pagination

Use `geared_pagination` — one call, variable-speed page sizes (15 → 30 → 50 → 100):

```ruby
def index
  set_page_and_extract_portion_from Current.account.cards.active.ordered
  # Sets @page with records, page number, last? flag, next_param
end
```

Cursor-based for large datasets (100k+ rows):

```ruby
set_page_and_extract_portion_from Event.all,
  ordered_by: { created_at: :desc, id: :desc }  # O(1) seeks, no OFFSET
```

Never use manual `limit`/`offset`. Never build a custom pagination service object.

---

## Error Handling and Strong Parameters

```ruby
# Raise on missing resource — Rails rescues with 404
@card = Current.user.accessible_cards.find_by!(number: params[:card_id])

# Validation failure
def create
  if @board.update(board_params)
    redirect_to @board
  else
    render :edit, status: :unprocessable_entity
  end
end

private
  def card_params
    params.require(:card).permit(:title, :description, :column_id, tag_ids: [])
  end
```

Never use `permit!`. Always permit only what's needed for the action.
