defmodule ExMoney.TransactionController do
  use ExMoney.Web, :controller

  alias ExMoney.{Transaction, Repo, Paginator}
  import Ecto.Query

  plug Guardian.Plug.EnsureAuthenticated, handler: ExMoney.Guardian.Unauthenticated
  plug :scrub_params, "transaction" when action in [:create, :update]

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    paginator = Transaction.by_user_id(user.id)
    |> order_by(desc: :made_on)
    |> preload(:transaction_info)
    |> Paginator.paginate(params)

    render(
      conn, :index,
      topbar: "dashboard",
      navigation: "transactions",
      transactions: paginator.entries,
      page_number: paginator.page_number,
      total_pages: paginator.total_pages
    )
  end

  def new(conn, _params) do
    changeset = Transaction.changeset(%Transaction{})
    render(conn, "new.html", changeset: changeset, topbar: "dashboard", navigation: "transactions")
  end

  def create(conn, %{"transaction" => transaction_params}) do
    changeset = Transaction.changeset(%Transaction{}, transaction_params)

    case Repo.insert(changeset) do
      {:ok, _transaction} ->
        conn
        |> put_flash(:info, "Transaction created successfully.")
        |> redirect(to: transaction_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, topbar: "dashboard", navigation: "transactions")
    end
  end

  def show(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    render(conn, "show.html", transaction: transaction, topbar: "dashboard", navigation: "transactions")
  end

  def edit(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)
    changeset = Transaction.changeset(transaction)
    render(conn, "edit.html", transaction: transaction, changeset: changeset, topbar: "dashboard", navigation: "transactions")
  end

  def update(conn, %{"id" => id, "transaction" => transaction_params}) do
    transaction = Repo.get!(Transaction, id)
    changeset = Transaction.changeset(transaction, transaction_params)

    case Repo.update(changeset) do
      {:ok, transaction} ->
        conn
        |> put_flash(:info, "Transaction updated successfully.")
        |> redirect(to: transaction_path(conn, :show, transaction))
      {:error, changeset} ->
        render(conn, "edit.html", transaction: transaction, changeset: changeset, topbar: "dashboard", navigation: "transactions")
    end
  end

  def delete(conn, %{"id" => id}) do
    transaction = Repo.get!(Transaction, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(transaction)

    conn
    |> put_flash(:info, "Transaction deleted successfully.")
    |> redirect(to: transaction_path(conn, :index))
  end
end
