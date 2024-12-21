using System.Collections;

namespace Microsoft.UpdateServices.Administration;

public abstract class WsusCollection : CollectionBase
{
    protected object this[int index]
    {
        get => throw new NotImplementedException();
        set => throw new NotImplementedException();
    }
}
