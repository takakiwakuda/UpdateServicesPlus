namespace Microsoft.UpdateServices.Administration;

public sealed class AdminProxy
{
    public static IUpdateServer GetUpdateServer()
    {
        throw new NotImplementedException();
    }

    public static IUpdateServer GetUpdateServer(string serverName, bool useSecureConnection)
    {
        throw new NotImplementedException();
    }

    public static IUpdateServer GetUpdateServer(string serverName, bool useSecureConnection, int portNumber)
    {
        throw new NotImplementedException();
    }

    public IUpdateServer GetUpdateServerInstance()
    {
        throw new NotImplementedException();
    }
}
