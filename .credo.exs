%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 12}
      ]
    }
  ]
}
