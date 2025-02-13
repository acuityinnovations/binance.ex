defmodule Binance.PortfolioMargin do
  @moduledoc false
  alias Binance.Rest.HTTPClient

  @endpoint "https://papi.binance.com"

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  # Server

  @doc """
  Pings Binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  @spec ping() :: {:ok, %{}, any()} | {:error, error()}
  def ping() do
    HTTPClient.get_binance("#{@endpoint}/papi/v1/ping")
  end

  def create_listen_key(params, config \\ nil) do
    arguments =
      if params[:timestamp] do
        params
      else
        Map.put(params, :timestamp, :os.system_time(:millisecond))
      end

    case HTTPClient.post_binance("#{@endpoint}/papi/v1/listenKey", arguments, config) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def create_order(order_type, params, config \\ nil, options \\ []) do
    arguments =
      if params[:timestamp] do
        params
      else
        Map.put(params, :timestamp, :os.system_time(:millisecond))
      end

    case HTTPClient.post_binance(
           "#{@endpoint}/papi/v1/#{order_type}/order",
           arguments,
           config,
           true,
           options
         ) do
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}

      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}

      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Binance.PortfolioMargin.MarginOrder.new(data), headers}

      error ->
        error
    end
  end

  def update_order(order_type, params, config \\ nil) do
    arguments =
      if params[:timestamp] do
        params
      else
        Map.put(params, :timestamp, :os.system_time(:millisecond))
      end

    case HTTPClient.put_binance(
           "#{@endpoint}/papi/v1/#{order_type}/order",
           arguments,
           config,
           true
         ) do
      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}

      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}

      error ->
        error
    end
  end

  def get_open_orders(order_type, params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/papi/v1/#{order_type}/openOrders", params, config) do
      {:ok, _data, _headers} = res -> res
      err -> err
    end
  end

  def get_order(order_type, params, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/papi/v1/#{order_type}/order", params, config) do
      {:ok, _data, _headers} = res -> res
      err -> err
    end
  end

  def cancel_order(order_type, params, config \\ nil) do
    case HTTPClient.delete_binance("#{@endpoint}/papi/v1/#{order_type}/order", params, config) do
      {:ok, %{"rejectReason" => _} = err, headers} ->
        {:error, err, headers}

      {:ok, data, headers} when order_type == "um" ->
        {:ok, Binance.PortfolioMargin.UMOrder.new(data), headers}

      {:ok, data, headers} when order_type == "cm" ->
        {:ok, Binance.PortfolioMargin.CMOrder.new(data), headers}

      {:ok, data, headers} when order_type == "margin" ->
        {:ok, Binance.PortfolioMargin.MarginOrder.new(data), headers}

      err ->
        err
    end
  end

  def cancel_all_orders(order_type, params, config \\ nil) do
    case HTTPClient.delete_binance(
           "#{@endpoint}/papi/v1/#{order_type}/allOpenOrders",
           params,
           config
         ) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end
end
