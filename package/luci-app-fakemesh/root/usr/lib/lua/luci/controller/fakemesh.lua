module("luci.controller.fakemesh", package.seeall)

function index()
entry({"admin", "services", "fakemesh"}, cbi("fakemesh"), _("FakeMesh"), 100)
end
