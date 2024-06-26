defmodule MarginTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Binance

  setup_all do
    HTTPoison.start()
  end

  test "get account status" do
    use_cassette "get_account_status" do
      assert {:ok, %{"data" => "Normal"}, _rate_limit} = Binance.Margin.get_account_status()
    end
  end

  describe ".create_listen_key" do
    test "returns a listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "margin/create_listen_key_ok" do
        assert {:ok,
                %{
                  "listenKey" => "cqcFKuqCCRv1QNnhiA4gsdMLSRgTz4qyd0l5JWryjaAxjQlr8JAcyksNt1Ct"
                }, _rate_limit} = Binance.Margin.create_listen_key()
      end
    end
  end

  describe ".create_isolated_listen_key" do
    test "returns a isolated listen key which could be used to subscrbe to a User Data stream" do
      use_cassette "margin/create_isolated_listen_key_ok" do
        assert {
                 :ok,
                 %{
                   "listenKey" => "JkPSgD5Eok8TdqkZeejhMyZDSGoFVuKakbdnCAeJxYO1E5swXs0M2KnKwkZH"
                 },
                 _rate_limit
               } = Binance.Margin.create_isolated_listen_key("BTCUSDT")
      end
    end
  end

  describe ".keep_alive_listen_key" do
    test "returns empty indicating the given listen key has been keepalive successfully" do
      use_cassette "margin/keep_alive_listen_key_ok" do
        assert {:ok, %{}, _rate_limit} =
                 Binance.Margin.keep_alive_listen_key(
                   "cqcFKuqCCRv1QNnhiA4gsdMLSRgTz4qyd0l5JWryjaAxjQlr8JAcyksNt1Ct"
                 )
      end
    end
  end

  describe ".keep_alive_isolated_listen_key" do
    test "returns empty indicating the given isolated listen key has been keepalive successfully" do
      use_cassette "margin/keep_alive_isolated_listen_key_ok" do
        assert {:ok, %{}, _rate_limit} =
                 Binance.Margin.keep_alive_isolated_listen_key(
                   "BTCUSDT",
                   "JkPSgD5Eok8TdqkZeejhMyZDSGoFVuKakbdnCAeJxYO1E5swXs0M2KnKwkZH"
                 )
      end
    end
  end

  describe ".get_account" do
    test "returns current account information" do
      use_cassette "margin/get_account_ok" do
        assert {
                 :ok,
                 %Binance.Margin.Account{
                   borrow_enabled: true,
                   margin_level: "999.00000000",
                   total_asset_of_btc: "0.08256500",
                   total_liability_of_btc: "0.00000000",
                   total_net_asset_of_btc: "0.08256500",
                   trade_enabled: true,
                   transfer_enabled: true
                 },
                 _rate_limit
               } = Binance.Margin.get_account()
      end
    end
  end

  describe ".create_order limit sell" do
    test "creates a cross margin order with a duration of good til cancel by default" do
      use_cassette "margin/order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.Margin.Order{} = response, _rate_limit} =
                 Binance.Margin.create_order(%{
                   symbol: "BTCUSDT",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 11_500,
                   time_in_force: "GTC"
                 })

        assert response.client_order_id == "7LUhU148oDLyZBEekAVrMu"
        assert response.cummulative_quote_qty == "0.00000000"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 2_868_628_287
        assert response.orig_qty == "0.00100000"
        assert response.price == "11500.00000000"
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_596_776_743_032
        assert response.type == "LIMIT"
        assert response.is_isolated == false
      end
    end

    test "creates an isolated margin order with a duration of good til cancel by default" do
      use_cassette "margin/isolated_order_limit_buy_good_til_cancel_default_duration_success" do
        assert {:ok, %Binance.Margin.Order{} = response, _rate_limit} =
                 Binance.Margin.create_order(%{
                   symbol: "BTCUSDT",
                   side: "BUY",
                   type: "LIMIT",
                   quantity: 0.001,
                   price: 11_500,
                   time_in_force: "GTC",
                   is_isolated: "TRUE"
                 })

        assert response.client_order_id == "default_9b2ca0e5bc314d59abe3f6073bf9"
        assert response.executed_qty == "0.00000000"
        assert response.order_id == 2_868_591_128
        assert response.orig_qty == "0.00100000"
        assert response.price == "11500.00000000"
        assert response.side == "BUY"
        assert response.status == "NEW"
        assert response.symbol == "BTCUSDT"
        assert response.time_in_force == "GTC"
        assert response.transact_time == 1_596_776_295_366
        assert response.type == "LIMIT"
        assert response.is_isolated == true
      end
    end
  end

  describe "get" do
    test "best ticker" do
      use_cassette "margin/get_best_ticker" do
        assert {:ok,
                %{
                  "askPrice" => "9046.59000000",
                  "askQty" => "0.49950000",
                  "bidPrice" => "9046.03000000",
                  "bidQty" => "0.62312800",
                  "symbol" => "BTCUSDT"
                }, _rate_limit} = Binance.Margin.get_best_ticker("BTCUSDT")
      end
    end

    test "index price" do
      use_cassette "margin/get_index_price" do
        assert {:ok,
                %{
                  "price" => "9180.25954545",
                  "symbol" => "BTCUSDT",
                  "calcTime" => 1_595_227_975_000
                }, _rate_limit} = Binance.Margin.get_index_price("BTCUSDT")
      end
    end
  end

  describe ".borrow" do
    test "borrow token (cross margin)" do
      use_cassette "margin/borrow_cross_margin" do
        assert {:ok, %{"tranId" => _}, _rate_limit} =
                 Binance.Margin.borrow(%{
                   asset: "USDT",
                   amount: 2
                 })
      end
    end

    test "borrow token (isolated margin)" do
      use_cassette "margin/borrow_isolated_margin" do
        assert {:ok, %{"tranId" => _}, _rate_limit} =
                 Binance.Margin.borrow(%{
                   is_isolated: "TRUE",
                   symbol: "BTCUSDT",
                   asset: "USDT",
                   amount: 2
                 })
      end
    end
  end

  describe "get cross collateral" do
    test "cross collateral wallet" do
      use_cassette "margin/cross_collateral_wallet_ok" do
        assert {
                 :ok,
                 %Binance.Margin.CrossCollateralWallet{
                   interest_free_limit: "0",
                   total_borrowed: "30.00996504",
                   total_cross_collateral: "78.87826688",
                   total_interest: "0.216",
                   asset: "USD",
                   cross_collaterals: [
                     %{
                       "collateralCoin" => "BTC",
                       "currentCollateralRate" => "0",
                       "interest" => "0",
                       "interestFreeLimitUsed" => "0",
                       "loanAmount" => "0",
                       "loanCoin" => "BUSD",
                       "locked" => "0",
                       "principalForInterest" => "0"
                     }
                   ]
                 },
                 _rate_limit
               } = Binance.Margin.get_cross_collateral_wallet()
      end
    end

    test "cross collateral info" do
      use_cassette "margin/cross_collateral_info_ok" do
        assert {
                 :ok,
                 [
                   %Binance.Margin.CrossCollateralInfo{
                     collateral_coin: "BTC",
                     current_collateral_rate: "0.87168984",
                     interest_grace_period: "0",
                     interest_rate: "0.0",
                     liquidation_collateral_rate: "0.98",
                     loan_coin: "USDT",
                     margin_call_collateral_rate: "0.95",
                     rate: "0.9"
                   }
                 ],
                 _rate_limit
               } =
                 Binance.Margin.get_cross_collateral_info(%{
                   loanCoin: "USDT",
                   collateralCoin: "BTC"
                 })
      end
    end
  end
end
