local Runner = require "nvim-test.runner"

local cstest = Runner:init({
  command = "dotnet",
  args = { "test" },
  file_pattern = "\\v(test/.*|Tests)\\.cs$",
  find_files = { "{name}Tests.{ext}", "Tests.{ext}" }, -- find testfile for a file
}, {
  c_sharp = [[
    ; Namespace
    ((namespace_declaration name: (qualified_name) @test-name) @scope-root)

    ; File Scoped Namespace
    ((file_scoped_namespace_declaration name: (qualified_name) @test-name) @scope-root)

    ; Class
    ((class_declaration name: (identifier) @test-name) @scope-root)

    ; Method
    ((method_declaration
        (attribute_list
            (attribute name: (identifier) @attribute-name
            (#match? @attribute-name "(Fact|Theory|Test|TestMethod)")
            ; attributes used by xunit, nunit and mstest
        ))
        name: (identifier) @test-name)
    @scope-root)

    ]],
})

function cstest:build_test_args(args, tests)
  table.insert(args, "--filter")
  table.insert(args, "FullyQualifiedName=" .. table.concat(tests, "."))
end

function cstest:build_args(args, _, opts)
  if opts.tests and #opts.tests > 0 then
      self:build_test_args(args, opts.tests)
  end
end

return cstest
