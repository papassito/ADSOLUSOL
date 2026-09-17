namespace ADSOLUSOL.Domain.Entities;

public enum EventProcessingStatus
{
    Pending,
    Accepted,
    Rejected,
    Processed,
    Failed,
    Duplicate
}
