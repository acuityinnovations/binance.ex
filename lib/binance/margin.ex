defmodule Binance.Margin do
  alias Binance.Rest.HTTPClient

  @endpoint "https://api.binance.com"

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  def create_listen_key(config \\ nil) do
    case HTTPClient.post_binance("#{@endpoint}/sapi/v1/userDataStream", %{}, config, false) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def create_isolated_listen_key(symbol, config \\ nil) do
    case HTTPClient.post_binance(
           "#{@endpoint}/sapi/v1/userDataStream/isolated",
           %{symbol: symbol},
           config,
           false
         ) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def keep_alive_listen_key(listen_key, config \\ nil) do
    arguments = %{
      listenKey: listen_key
    }

    case HTTPClient.put_binance("#{@endpoint}/sapi/v1/userDataStream", arguments, config, false) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def keep_alive_isolated_listen_key(symbol, listen_key, config \\ nil) do
    arguments = %{
      symbol: symbol,
      listenKey: listen_key
    }

    case HTTPClient.put_binance(
           "#{@endpoint}/sapi/v1/userDataStream/isolated",
           arguments,
           config,
           false
         ) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  def get_account(config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/account", %{}, config) do
      {:ok, data, headers} ->
        {:ok, Binance.Margin.Account.new(data), headers}

      error ->
        error
    end
  end

  def get_isolated_account(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/isolated/account", params, config) do
      {:ok, data, headers} ->
        {:ok, Binance.Margin.IsolatedAccount.new(data), headers}

      error ->
        error
    end
  end

  def get_index_price(instrument, config \\ nil) do
    case HTTPClient.get_binance(
           "#{@endpoint}/sapi/v1/margin/priceIndex",
           %{symbol: instrument},
           config
         ) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_best_ticker(String.t()) :: {:ok, map(), any()} | {:error, error()}
  def get_best_ticker(instrument) do
    case HTTPClient.get_binance("#{@endpoint}/api/v3/ticker/bookTicker?symbol=#{instrument}") do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_kline_data(String.t(), String.t(), number) :: {:ok, map(), any()} | {:error, error()}
  def get_kline_data(instrument, interval, limit) do
    case HTTPClient.get_binance(
           "#{@endpoint}/api/v3/klines?symbol=#{instrument}&interval=#{interval}&limit=#{limit}"
         ) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  def get_account_status(config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/account/status", %{}, config) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  def create_order(params, config \\ nil, options \\ []) do
    arguments =
      if params[:timestamp] do
        params
      else
        Map.put(params, :timestamp, :os.system_time(:millisecond))
      end

    case HTTPClient.post_binance(
           "#{@endpoint}/sapi/v1/margin/order",
           arguments,
           config,
           true,
           options
         ) do
      {:ok, data, headers} ->
        {:ok, Binance.Margin.Order.new(data), headers}

      error ->
        error
    end
  end

  @spec get_open_orders(map(), map() | nil) ::
          {:ok, list(), any()} | {:error, error()}
  def get_open_orders(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/openOrders", params, config) do
      {:ok, data, headers} -> {:ok, Enum.map(data, &Binance.Margin.Order.new(&1)), headers}
      err -> err
    end
  end

  def cancel_order(params, config \\ nil) do
    case HTTPClient.delete_binance("#{@endpoint}/sapi/v1/margin/order", params, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, Binance.Margin.Order.new(data), headers}
      err -> err
    end
  end

  def get_order(params, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/order", params, config) do
      {:ok, data, headers} -> {:ok, Binance.Margin.Order.new(data), headers}
      err -> err
    end
  end

  def cancel_all_orders(params, config \\ nil) do
    case HTTPClient.delete_binance("#{@endpoint}/sapi/v1/margin/openOrders", params, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @doc """
  https://binance-docs.github.io/apidocs/spot/en/#margin-account-borrow-margin

  is_isolated: can be either "TRUE" or "FALSE". If "TRUE", symbol must be present.
  symbol: instrument like BTCUSDT, etc
  asset: currency like USDT or BTC, etc
  amount: how many tokens to borrow

  """
  def borrow(params, config \\ nil) do
    arguments =
      if params[:timestamp] do
        params
      else
        Map.put(params, :timestamp, :os.system_time(:millisecond))
      end

    HTTPClient.post_binance("#{@endpoint}/sapi/v1/margin/loan", arguments, config)
  end

  @doc """
  https://binance-docs.github.io/apidocs/spot/en/#cross-collateral-wallet-v2-user_data
  Get the cross collateral wallet of a specific account
  """
  @spec get_cross_collateral_wallet(map() | nil) ::
          {:ok, Binance.Margin.CrossCollateralWallet, any()} | {:error, error()}
  def get_cross_collateral_wallet(config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v2/futures/loan/wallet", %{}, config) do
      {:ok, data, headers} ->
        {:ok, Binance.Margin.CrossCollateralWallet.new(data), headers}

      error ->
        error
    end
  end

  @doc """
  https://binance-docs.github.io/apidocs/spot/en/#cross-collateral-information-v2-user_data
  Retrieve the cross collateral information for a specific loan coin and cross collateral coin
  So, the params will contain the loan coin and cross collateral coin.
  If the param is empty, it will return the all cross collateral
  Ex: Binance.Margin.get_cross_collateral_info(
  %{"loanCoin": "USDT", "collateralCoin": "BTC"},
  %{access_keys: ["TEST_BIN_API_KEY", "TEST_BIN_API_SECRET"]}
  )
  {:ok,
  [
   %Binance.Margin.CrossCollateralInfo{
     collateral_coin: "BTC",
     current_collateral_rate: "0",
     interest_grace_period: "2",
     interest_rate: "0.0024",
     liquidation_collateral_rate: "0.9",
     loan_coin: "USDT",
     margin_call_collateral_rate: "0.8",
     rate: "0.65"
   }
  ]}
  """
  @spec get_cross_collateral_info(map(), map() | nil) ::
          {:ok, list(Binance.Margin.CrossCollateralInfo), any()} | {:error, error()}
  def get_cross_collateral_info(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v2/futures/loan/configs", params, config) do
      {:ok, data, headers} ->
        {:ok, Enum.map(data, &Binance.Margin.CrossCollateralInfo.new(&1)), headers}

      error ->
        error
    end
  end

  @doc """
  https://binance-docs.github.io/apidocs/spot/en/#query-cross-margin-fee-data-user_data
  Query the margin fee data for a specific account. Support 2 mode cross and isolated
  """
  def get_margin_fee(type, params \\ %{}, config \\ nil)

  def get_margin_fee(:cross_margin, params, config) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/crossMarginData", params, config) do
      {:ok, data, headers} ->
        {:ok, Enum.map(data, &Binance.Margin.CrossMarginFee.new(&1)), headers}

      error ->
        error
    end
  end

  def get_margin_fee(:isolated_margin, params, config) do
    case HTTPClient.get_binance("#{@endpoint}/sapi/v1/margin/isolatedMarginData", params, config) do
      {:ok, data, headers} ->
        {:ok, Enum.map(data, &Binance.Margin.IsoMarginFee.new(&1)), headers}

      error ->
        error
    end
  end

  def get_trades(
        %{symbol: symbol} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      timestamp: params[:timestamp] || :os.system_time(:millisecond)
    }

    arguments =
      arguments
      |> Map.merge(
        unless(
          is_nil(params[:start_time]),
          do: %{startTime: params[:start_time]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:end_time]),
          do: %{endTime: params[:end_time]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:from_id]),
          do: %{fromId: params[:from_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:order_id]),
          do: %{orderId: params[:order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:is_isolated]),
          do: %{isIsolated: params[:is_isolated]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(
          is_nil(params[:limit]),
          do: %{limit: params[:limit]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    HTTPClient.get_binance("/sapi/v1/margin/myTrades", arguments, config)
  end
end
