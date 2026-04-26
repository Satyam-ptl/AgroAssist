from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from AgroAssist_Backend.crops.models import Crop
from AgroAssist_Backend.farmers.models import Farmer
from AgroAssist_Backend.tasks.models import FarmerTask


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    now = timezone.localdate()

    if request.user.is_staff or request.user.is_superuser:
        return Response({
            'total_crops': Crop.objects.count(),
            'total_farmers': Farmer.objects.count(),
            'pending_tasks': FarmerTask.objects.filter(status='Pending').count(),
            'overdue_tasks': FarmerTask.objects.filter(
                due_date__lt=now,
                status__in=['Pending', 'In Progress'],
            ).count(),
            'completed_tasks': FarmerTask.objects.filter(status='Completed').count(),
        })

    farmer = getattr(request.user, 'farmer', None)
    if farmer is None:
        farmer = Farmer.objects.filter(email__iexact=request.user.email).first()

    if farmer is None:
        return Response({'total_crops': Crop.objects.count()})

    return Response({
        'total_crops': Crop.objects.count(),
        'my_pending_tasks': FarmerTask.objects.filter(
            farmer=farmer,
            status='Pending',
        ).count(),
        'my_overdue_tasks': FarmerTask.objects.filter(
            farmer=farmer,
            due_date__lt=now,
            status__in=['Pending', 'In Progress'],
        ).count(),
        'my_completed_tasks': FarmerTask.objects.filter(
            farmer=farmer,
            status='Completed',
        ).count(),
    })
