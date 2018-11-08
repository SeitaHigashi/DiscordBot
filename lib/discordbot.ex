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
    case msg.content do
      # In general, you don't want to match using the binary notation, but I'm
      # doing it here to be explicit
      # <<"!" :: binary, "ping" :: binary>> ->
      "!ping" ->
        Api.create_message(msg.channel_id, "I copy and pasted this code")

      n when n in ["Hello", "Good morning", "Good night"] ->
        Api.create_message(msg.channel_id, msg.content <> "! " <> msg.author.username)

      _ ->
        :ignore
    end

    {:ok, state}
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_, state) do
    {:ok, state}
  end
end
