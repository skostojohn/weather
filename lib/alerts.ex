defmodule Weather.Alerts do
  use Memento.Table, attributes: [:state, :alerts, :updated_at]
end
