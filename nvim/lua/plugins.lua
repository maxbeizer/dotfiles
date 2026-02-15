-- Backwards-compatible shim for older init.vim loaders.
local ok, maxbeizer = pcall(require, 'maxbeizer')
if ok and maxbeizer.setup then
  maxbeizer.setup()
end

return {}
