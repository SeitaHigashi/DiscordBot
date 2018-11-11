defmodule Discordbot do
  def start do
    import Supervisor.Spec

    # List comprehension creates a consumer per cpu core
    children = for i <- 1..System.schedulers_online(), do: worker(ExampleConsumer, [], id: i)

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule ExampleConsumer do
  use Nostrum.Consumer

  alias Nostrum.Api

  require Logger


  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}, state) do
    botname = Application.get_env(:nostrum, :botname, "Elix")
    {_,%{ "id" => current_id }} = Api.get_current_user()
    if msg.author.id != current_id do
      message = msg.content |> String.split(" ")
      case message do
      [^botname | command ] ->
        Api.create_message(msg.channel_id, commandresponse(command))
      [_] ->
        if keyword_match(msg, Application.get_env(:nostrum, :exactmatch, [])) do
          Api.create_message(msg.channel_id, msg.content <> "! " <> msg.author.username)
        end
      _ -> :ignore
      end
    end

    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def commandresponse(msg) do
    case msg do
      ["get_token" | _] -> Api.get_token
    end
  end

  def keyword_match(msg, env) do
    message = msg.content |> String.downcase
    Enum.find_value(env, false, fn key -> String.downcase(key) == message end)
  end

end
