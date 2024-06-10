%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          {Credo.Check.Readability.ModuleDoc, []}
        ],
        extra: [
          {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 12}
        ]
      }
    }
  ]
}
