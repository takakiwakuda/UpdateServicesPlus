namespace Microsoft.UpdateServices.Administration;

public interface IComputerTargetGroup
{
    Guid Id { get; }
    string Name { get; }

    void Delete();
}
