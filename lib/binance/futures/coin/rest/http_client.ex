defmodule Binance.Futures.Coin.Rest.HTTPClient do
  @endpoint "https://dapi.binance.com"
  @used_order_limit "X-MBX-ORDER-COUNT-1M"
  @used_weight_limit "X-MBX-USED-WEIGHT-1M"

  alias Binance.{Config, Util}

  def get_binance(url, headers \\ []) when is_list(headers) do
    HTTPoison.get("#{@endpoint}#{url}", headers)
    |> parse_response
  end

  def delete_binance(url, headers \\ []) when is_list(headers) do
    HTTPoison.delete("#{@endpoint}#{url}", headers)
    |> parse_response(:rate_limit)
  end

  def get_binance(url, params, config) do
    case prepare_request(:get, url, params, config, true) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        get_binance(url, headers)
    end
  end

  def delete_binance(url, params, config) do
    case prepare_request(:delete, url, params, config, true) do
      {:error, _} = error ->
        error

      {:ok, url, headers} ->
        delete_binance(url, headers)
    end
  end

  def post_binance(url, params, config, signed? \\ true) do
    case prepare_request(:post, url, params, config, signed?) do
      {:error, _} = error ->
        error

      {:ok, url, headers, body} ->
        case HTTPoison.post("#{@endpoint}#{url}", body, headers) do
          {:error, err} ->
            rate_limit = parse_rate_limits(err)
            {:error, {:http_error, err}, rate_limit}

          {:ok, %{status_code: status_code} = response} when status_code not in 200..299 ->
            rate_limit = parse_rate_limits(response)

            case Poison.decode(response.body) do
              {:ok, %{"code" => code, "msg" => msg}} ->
                {:error, {:binance_error, %{code: code, msg: msg}}, rate_limit}

              {:error, err} ->
                {:error, {:poison_decode_error, err}, rate_limit}
            end

          {:ok, response} ->
            rate_limit = parse_rate_limits(response)

            case Poison.decode(response.body) do
              {:ok, data} -> {:ok, data, rate_limit}
              {:error, err} -> {:error, {:poison_decode_error, err}, rate_limit}
            end
        end
    end
  end

  defp parse_rate_limits(%HTTPoison.Response{headers: headers}) do
    rates =
      headers
      |> Enum.reduce(
        %{},
        fn {k, v}, acc ->
          case String.upcase(k) do
            @used_order_limit -> Map.put(acc, :used_order_limit, v)
            @used_weight_limit -> Map.put(acc, :used_weight_limit, v)
            _ -> acc
          end
        end
      )

    if map_size(rates) != 0, do: rates, else: nil
  end

  defp parse_rate_limits(_) do
    nil
  end

  def put_binance(url, params, config, signed? \\ true) do
    case prepare_request(:put, url, params, config, signed?) do
      {:error, _} = error ->
        error

      {:ok, url, headers, body} ->
        case HTTPoison.put("#{@endpoint}#{url}", body, headers) do
          {:error, err} ->
            {:error, {:http_error, err}}

          {:ok, %{status_code: status_code} = response} when status_code not in 200..299 ->
            case Poison.decode(response.body) do
              {:ok, %{"code" => code, "msg" => msg}} ->
                {:error, {:binance_error, %{code: code, msg: msg}}}

              {:error, err} ->
                {:error, {:poison_decode_error, err}}
            end

          {:ok, %{body: ""}} ->
            {:ok, ""}

          {:ok, response} ->
            case Poison.decode(response.body) do
              {:ok, data} -> {:ok, data}
              {:error, err} -> {:error, {:poison_decode_error, err}}
            end
        end
    end
  end

  def prepare_request(method, url, params, config, signed?) do
    case validate_credentials(config) do
      {:error, _} = error ->
        error

      {:ok, %Config{api_key: api_key, api_secret: api_secret}} ->
        cond do
          method in [:get, :delete] ->
            headers = [
              {"X-MBX-APIKEY", api_key}
            ]

            params =
              params
              |> Map.merge(%{timestamp: :os.system_time(:millisecond)})
              |> Enum.reduce(
                params,
                fn x, acc ->
                  Map.put(
                    acc,
                    elem(x, 0),
                    if is_list(elem(x, 1)) do
                      ele =
                        x
                        |> elem(1)
                        |> Enum.join(",")

                      "[#{ele}]"
                    else
                      elem(x, 1)
                    end
                  )
                end
              )

            argument_string = URI.encode_query(params)
            signature = Util.sign_content(api_secret, argument_string)

            {:ok, "#{url}?#{argument_string}&signature=#{signature}", headers}

          method in [:post, :put] ->
            headers = [
              {"X-MBX-APIKEY", api_key},
              {"Content-Type", "application/x-www-form-urlencoded"}
            ]

            argument_string = URI.encode_query(params)

            argument_string =
              case signed? do
                true ->
                  signature = Util.sign_content(api_secret, argument_string)
                  "#{argument_string}&signature=#{signature}"

                false ->
                  argument_string
              end

            {:ok, url, headers, argument_string}
        end
    end
  end

  defp validate_credentials(config) do
    case Config.get(config) do
      %Config{api_key: api_key, api_secret: api_secret} = config
      when is_binary(api_key) and is_binary(api_secret) ->
        {:ok, config}

      _ ->
        {:error, {:config_missing, "Secret or API key missing"}}
    end
  end

  defp parse_response({:error, err}, :rate_limit) do
    {:error, {:http_error, err}, parse_rate_limits(err)}
  end

  defp parse_response({:ok, %{status_code: status_code} = response}, :rate_limit)
       when status_code not in 200..299 do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, parse_rate_limits(response)}

      {:error, error} ->
        {:error, {:poison_decode_error, error}, parse_rate_limits(response)}
    end
  end

  defp parse_response({:ok, response}, :rate_limit) do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, data} -> {:ok, data, parse_rate_limits(response)}
      {:error, error} -> {:error, {:poison_decode_error, error}, parse_rate_limits(response)}
    end
  end

  defp parse_response({:error, err}) do
    {:error, {:http_error, err}}
  end

  defp parse_response({:ok, %{status_code: status_code} = response})
       when status_code not in 200..299 do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, %{"code" => code, "msg" => msg}} ->
        {:error, {:binance_error, %{code: code, msg: msg}}}

      {:error, error} ->
        {:error, {:poison_decode_error, error}}
    end
  end

  defp parse_response({:ok, response}) do
    response.body
    |> Poison.decode()
    |> case do
      {:ok, data} -> {:ok, data}
      {:error, error} -> {:error, {:poison_decode_error, error}}
    end
  end
end
