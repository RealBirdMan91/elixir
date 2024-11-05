defmodule Servy.Handler do
  @moduledoc """
  Documentation for `Servy.Handler`.
  """

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Parser
  alias Servy.Conv
  alias Servy.BearController
  alias Servy.Fetcher
  alias Servy.VideoCam

  def handle(request) do
    request
    |> parse()
    |> route()
    |> format_response()
  end

  @doc """
  Route a request to a response struct.
  """

  def route(%Conv{method: "GET", path: "/sensors"} = conv) do
    sensor_data = Servy.SensorServer.get_sensor_data()
    %Conv{conv | status: 200, resp_body: sensor_data}
  end

  def route(%Conv{method: "GET", path: "/snapshots"} = conv) do
    results =
      [
        Fetcher.async(fn -> VideoCam.get_snapshot("camera1") end),
        Fetcher.async(fn -> VideoCam.get_snapshot("camera2") end),
        Fetcher.async(fn -> VideoCam.get_snapshot("camera3") end),
        Fetcher.async(fn -> Servy.Tracker.get_location("bigfoot") end)
      ]
      |> Enum.map(&Fetcher.get_result/1)

    %{conv | status: 200, resp_body: inspect(results)}
  end

  def route(%Conv{method: "POST", path: "/pledges"} = conv) do
    Servy.PledgeController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pledges"} = conv) do
    Servy.PledgeController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %Conv{conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/about"} = conv) do
    case File.read("#{@pages_path}/about.html") do
      {:ok, content} ->
        %Conv{conv | status: 200, resp_body: content}

      {:error, :enoent} ->
        %Conv{conv | status: 404, resp_body: "File not found"}

      {:error, reason} ->
        %Conv{conv | status: 500, resp_body: "Internal Server Error, reason: #{reason}"}
    end
  end

  def route(%Conv{} = conv) do
    %Conv{conv | status: 404, resp_body: "Not Found"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: "#{conv.resp_content_type}"\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end

request = """
GET /api/bears HTTP/1.1\r
Host: example.com\r
User-Agent: ExampleBrowser/1.0\r
Accept: */*\r
\r
"""

res = Servy.Handler.handle(request)
IO.puts(res)
