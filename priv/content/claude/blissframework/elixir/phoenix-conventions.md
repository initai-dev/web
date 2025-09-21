# Phoenix Conventions

Phoenix framework development guidelines within the Bliss Framework methodology.

## Project Structure

### Standard Phoenix Layout
```
lib/
├── my_app/
│   ├── application.ex          # OTP Application
│   ├── repo.ex                # Ecto Repository
│   └── accounts/              # Domain Context
│       ├── user.ex           # Schema
│       └── user_token.ex     # Schema
├── my_app_web/
│   ├── endpoint.ex           # HTTP Endpoint
│   ├── router.ex             # URL Routing
│   ├── telemetry.ex          # Metrics
│   ├── controllers/          # HTTP Controllers
│   ├── views/                # View Logic
│   ├── templates/            # HTML Templates
│   └── live/                 # LiveView Components
```

## Context Organization

### Domain Contexts
- Group related functionality into contexts
- Use clear, domain-specific names
- Keep contexts focused and cohesive

```elixir
defmodule MyApp.Accounts do
  @moduledoc """
  The Accounts context manages user authentication and profiles.
  """

  alias MyApp.Accounts.User
  alias MyApp.Repo

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Context Boundaries
- Avoid circular dependencies between contexts
- Use well-defined APIs between contexts
- Keep database access within context modules

## Controller Patterns

### Action Structure
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
```

### Error Handling
- Use pattern matching for success/error cases
- Provide meaningful flash messages
- Handle edge cases gracefully

## Schema and Changeset Patterns

### Schema Definition
```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :age, :integer

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :age])
    |> validate_required([:email, :name])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
```

### Changeset Conventions
- Use descriptive changeset function names
- Validate data thoroughly
- Use constraints for database-level validations

## LiveView Best Practices

### Component Structure
```elixir
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view

  alias MyApp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()
    {:ok, assign(socket, :users, users)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)

    users = Accounts.list_users()
    {:noreply, assign(socket, :users, users)}
  end
end
```

### State Management
- Keep socket assigns minimal and focused
- Use temporary assigns for large datasets
- Handle loading states appropriately

## Testing Patterns

### Context Testing
```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  alias MyApp.Accounts

  describe "users" do
    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@example.com", name: "Test User"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "test@example.com"
      assert user.name == "Test User"
    end
  end
end
```

### Controller Testing
```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  describe "GET /users" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Users"
    end
  end
end
```

These conventions ensure consistent Phoenix application structure and promote maintainable, testable code across all projects.