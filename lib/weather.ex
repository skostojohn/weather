defmodule Weather do
  def get_weather_alerts(state) do
    case get_weather_from_db(state) do
      nil ->
        api_results = get_weather_from_api(state)
        store_weather(state, api_results)
        IO.inspect("from api:")
        api_results

      results ->
        IO.inspect("from db:")
        results
    end
  end

  defp get_weather_from_db(state) do
    Memento.transaction!(fn ->
      case Memento.Query.read(Weather.Alerts, state) do
        nil ->
          nil

        %Weather.Alerts{alerts: alerts, updated_at: timestamp} ->
          cond do
            :os.system_time(:millisecond) - timestamp > 120_000 ->
              nil

            true ->
              alerts
          end
      end
    end)
  end

  defp get_weather_from_api(state) do
    case HTTPoison.get("https://api.weather.gov/alerts/active?area=" <> state) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, %{"features" => feature_list}} = Jason.decode(body)

        Enum.map(feature_list, fn item ->
          %{"properties" => %{"headline" => headline}} = item
          headline
        end)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  defp store_weather(state, api_results) do
    Memento.transaction!(fn ->
      Memento.Query.write(%Weather.Alerts{
        state: state,
        alerts: api_results,
        updated_at: :os.system_time(:millisecond)
      })
    end)
  end
end
