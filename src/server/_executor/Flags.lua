local run_svc = game:GetService('RunService')

return {
    IS_STUDIO = run_svc:IsStudio();
    DEVELOPER_MODE = false;
}