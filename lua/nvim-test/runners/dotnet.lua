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
  table.insert(args, "FullyQualifiedName=" .. table.concat(tests, "."))
end

function cstest:build_args(args, filename, opts)
  table.insert(args, "--filter")
  if filename then
    table.insert(args, "FullyQualifiedName~" .. table.concat(cstest:get_namespace_and_class_name(), "."))
  end
  if opts.tests and #opts.tests > 0 then
      self:build_test_args(args, opts.tests)
  end
end

function cstest:get_namespace_and_class_name()
  local ts_utils = require "nvim-treesitter.ts_utils"
  local ts_parsers = require("nvim-treesitter.parsers")
  local ts = vim.treesitter
  local query = ts.get_query(ts_parsers.ft_to_lang("c_sharp"), "nvim-test")
  local result = {}
  if query then
    local curnode = ts_utils.get_node_at_cursor()
    while curnode do
      local iter = query:iter_captures(curnode, 0)
      local capture_id, capture_node = iter()
      if capture_node == curnode and query.captures[capture_id] == "scope-root" then
        if query.captures[capture_id] == "attribute-name" then
            do break end
        end
        while query.captures[capture_id] ~= "test-name" do
          capture_id, capture_node = iter()
          if not capture_id then
            return result
          end
        end
        local name = self:parse_testname(ts.query.get_node_text(capture_node, 0))
        table.insert(result, 1, name)
      end
      curnode = curnode:parent()
    end
  end
  return result
end

return cstest
