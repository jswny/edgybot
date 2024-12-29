defmodule Edgybot.ObanJobManager do
  use GenServer
  import Ecto.Query
  alias Edgybot.Repo
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    Process.send_after(self(), :resume_orphaned_jobs, 0)
    {:ok, nil}
  end

  @impl true
  def handle_info(:resume_orphaned_jobs, _state) do
    resume_orphaned_jobs()
    {:noreply, nil}
  end

  def resume_orphaned_jobs do
    %{node: node_id} = Oban.config()

    query =
      from(j in Oban.Job,
        where: j.state == "executing",
        where: fragment("?[1] = ?", j.attempted_by, ^node_id)
      )

    query
    |> Repo.all()
    |> Enum.each(fn job ->
      Logger.info("Resuming orphaned job from worker #{job.worker}: #{inspect(job)}")

      job
      |> Ecto.Changeset.change(state: "available")
      |> Repo.update()
    end)
  end
end
