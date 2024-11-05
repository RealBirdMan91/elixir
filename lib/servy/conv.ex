defmodule Servy.Conv do
  defstruct method: "",
            path: "",
            resp_body: "",
            status: nil,
            params: %{},
            headers: %{},
            resp_content_type: "text/html"

  @doc """
  Return a string representation of the status code and reason.

  ## Examples

      iex> Servy.Conv.full_status(%Servy.Conv{status: 200})
      "200 OK"

      iex> Servy.Conv.full_status(%Servy.Conv{status: 404})
      "404 Not Found"
  """
  def full_status(%Servy.Conv{} = conv) do
    "#{conv.status} #{status_reason(conv.status)}"
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end
