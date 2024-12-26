namespace Microsoft.UpdateServices.Administration;

public interface IUpdateServer
{
    IComputerTargetGroup CreateComputerTargetGroup(string name);
    IComputerTargetGroup GetComputerTargetGroup(Guid id);
    ComputerTargetGroupCollection GetComputerTargetGroups();
}
