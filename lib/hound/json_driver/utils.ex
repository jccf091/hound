defmodule Hound.JsonDriver.Utils do
  @moduledoc false

  def make_req(type, path, params // []) do
    url = get_url(path)

    if params != [] && type == :post do
      headers = [{'Content-Type', 'text/json'}]
      {:ok, body} = JSEX.encode params
    else
      headers = []
      body = ""
    end

    {:ok, status, _headers, content} = :ibrowse.send_req(url, headers, type, body)
    resp = decode_content(content)

    {status, _} = :string.to_integer(status)

    cond do
      resp["status"] == 0 && path == "session" ->
        {:ok, resp["sessionId"]}
      resp["status"] == 0 ->
        resp["value"]
      status < 300 ->
        :ok
      true ->
        if resp["value"] do
          raise resp["value"]["message"]
        else
          raise """
          Webdriver call status code #{status} for #{url}.
          Check if webdriver server is running. Make sure it supports the feature being requested.
          """
        end
    end
  end


  defp decode_content(content) do
    if content != [] do
      {:ok, resp} = JSEX.decode("#{content}")
      resp
    else
      []
    end
  end

  defp get_url(path) do
    {:ok, _driver, driver_info} = Hound.get_driver_info
    host = driver_info[:host] || "http://localhost"
    port = driver_info[:port] || 4444
    '#{host}:#{port}/wd/hub/#{path}'
  end

end
