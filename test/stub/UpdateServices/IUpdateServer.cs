namespace Microsoft.UpdateServices.Administration;

public interface IUpdateServer
{
    IComputerTargetGroup CreateComputerTargetGroup(string name);
    ComputerTargetGroupCollection GetComputerTargetGroups();
}
