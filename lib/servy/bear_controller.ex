defmodule Servy.BearController do
  alias Servy.Conv
  alias Servy.Wildthings

  def index(conv) do
    bears =
      Wildthings.list_bears()
      |> Enum.sort(fn b1, b2 -> b1.name <= b2.name end)
      |> Enum.map(& &1.name)
      |> Enum.join(", ")

    %Conv{conv | status: 200, resp_body: bears}
  end

  def show(conv, %{"id" => id}) do
    %Conv{conv | status: 200, resp_body: "Bear #{id}"}
  end

  def create(conv, %{"name" => name, "type" => type}) do
    %Conv{
      conv
      | status: 201,
        resp_body: "#{name} the #{type} bear created"
    }
  end
end
