-- Autologin retry removed for the Triumvirate login UI build.
function Autologin()
    if AutologinControlPanel then AutologinControlPanel:Hide(); end
    if AutologinRetryButton then AutologinRetryButton:Hide(); end
    if AutologinStatusText then AutologinStatusText:SetText(""); end
    if AutologinStatusBox then AutologinStatusBox:Hide(); end
end
