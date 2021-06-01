defmodule Binance.Config do
  require Logger

  @type t :: %Binance.Config{
          api_key: String.t(),
          api_secret: String.t()
        }

  @enforce_keys [:api_key, :api_secret]
  defstruct [:api_key, :api_secret]

  @doc """
  Get default API configs

  ## Examples
      iex> Binance.Config.get()
  """
  def get(nil) do
    %__MODULE__{
      api_key: System.get_env("BINANCE_API_KEY"),
      api_secret: System.get_env("BINANCE_API_SECRET")
    }
  end

  @doc """
  Get static API configs passed in directly

  ## Examples
      iex> Binance.Config.get(%{api_key: "abcdef", secret_key: "123456"})
  """
  def get(%{
        api_key: api_key,
        secret_key: secret_key
      }) do
    %__MODULE__{
      api_key: api_key,
      api_secret: secret_key
    }
  end

  def get(_) do
    Logger.error("Incorrect config setup.")
  end
end
