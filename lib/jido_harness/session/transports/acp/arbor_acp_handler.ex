defmodule Jido.Harness.SessionAdapters.ACP.ArborACPHandler do
  @moduledoc false
  @behaviour Arbor.ACP.Client.Handler

  @impl true
  def init(opts), do: {:ok, %{transport: Keyword.fetch!(opts, :transport)}}

  @impl true
  def handle_session_update(session_id, update, state) do
    handle_session_update(session_id, update, nil, state)
  end

  @impl true
  def handle_session_update(session_id, update, message, state) do
    send(state.transport, {:acp_session_update, session_id, update, message})
    {:ok, state}
  end

  @impl true
  def handle_permission_request(session_id, tool_call, options, state) do
    handle_permission_request(session_id, tool_call, options, nil, state)
  end

  @impl true
  def handle_permission_request(session_id, tool_call, options, message, state) do
    ref = make_ref()

    send(
      state.transport,
      {:acp_permission_request, self(), ref, session_id, tool_call, options, message}
    )

    receive do
      {:jido_harness_approval_response, ^ref, outcome} -> {:ok, outcome, state}
    end
  end

  @impl Arbor.ACP.Client.Handler
  def handle_form_elicitation(params, state) do
    transport = state.transport
    turn_id = GenServer.call(transport, :elicitation_turn)

    work = fn ->
      ref = make_ref()
      send(transport, {:acp_form_elicitation, self(), ref, turn_id, params})

      receive do
        {:jido_harness_elicitation_response, ^ref, response} -> {:ok, response}
      end
    end

    {:async, work, state}
  end
end
