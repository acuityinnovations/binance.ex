defmodule Binance.Util do
  @moduledoc false

  @doc """
  Sign a given string using given key
  """
  def sign_content(key, content) do
    :crypto.mac(
      :hmac,
      :sha256,
      key,
      content
    )
    |> Base.encode16()
  end
end
