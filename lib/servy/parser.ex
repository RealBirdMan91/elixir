defmodule Servy.Parser do
  alias Servy.Conv

  def parse(request) do
    [top, params_strings] = String.split(request, "\r\n\r\n")
    [request_line | header_lines] = String.split(top, "\r\n")
    [method, path, _http] = String.split(request_line, " ")

    headers = parse_headers(header_lines)
    params = parse_params(headers["Content-Type"], params_strings)

    %Conv{
      method: method,
      headers: headers,
      params: params,
      path: path
    }
  end

  defp parse_params("application/x-www-form-urlencoded", params_string) do
    params_string
    |> String.trim()
    |> URI.decode_query()
  end

  defp parse_params(_, _), do: %{}

  defp parse_headers(header_lines) do
    Enum.reduce(header_lines, %{}, fn line, acc ->
      [key, value] = String.split(line, ": ")
      Map.put(acc, key, value)
    end)
  end
end
