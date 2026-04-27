from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models.functions import Lower

from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation
from .serializers import (
    CropSerializer, CropGuideSerializer, CropGrowthStageSerializer,
    CropCareTaskSerializer, CropRecommendationSerializer, CropDetailSerializer
)


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 100
    page_size_query_param = 'page_size'
    max_page_size = 200


class CropViewSet(viewsets.ModelViewSet):
    serializer_class = CropSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'growth_duration_days', 'created_at']
    ordering = ['name']
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        queryset = Crop.objects.all()
        name = self.request.query_params.get('name')
        category = self.request.query_params.get('category')
        crop_type = self.request.query_params.get('crop_type')
        season = self.request.query_params.get('season')
        state = self.request.query_params.get('state')

        if name:
            queryset = queryset.filter(name__icontains=name.strip())
        if category:
            queryset = queryset.filter(category__icontains=category.strip())
        if crop_type:
            queryset = queryset.filter(crop_type__icontains=crop_type.strip())
        if season:
            queryset = queryset.filter(season__iexact=season.strip())
        if state:
            queryset = queryset.filter(states__icontains=state.strip())

        return queryset.order_by('name')

    @action(detail=False, methods=['get'], url_path='seasons')
    def seasons(self, request):
        raw_seasons = (
            Crop.objects.exclude(season__isnull=True)
            .exclude(season__exact='')
            .values_list('season', flat=True)
        )

        canonical = {
            'kharif': 'Kharif',
            'rabi': 'Rabi',
            'summer': 'Summer',
        }
        seen = set()
        normalized = []

        for season in raw_seasons:
            cleaned = season.strip()
            if not cleaned:
                continue

            key = cleaned.lower()
            if key in seen:
                continue

            seen.add(key)
            normalized.append(canonical.get(key, cleaned.title()))

        return Response(sorted(normalized, key=lambda s: s.lower()))

    @action(detail=False, methods=['get'], url_path='states')
    def states(self, request):
        all_states = set()
        crops_with_states = (
            Crop.objects.exclude(states__isnull=True)
            .exclude(states__exact='')
            .values_list('states', flat=True)
        )
        for states_str in crops_with_states:
            for state in states_str.split(','):
                state = state.strip()
                if state:
                    all_states.add(state)
        return Response(sorted(all_states))

    @action(detail=False, methods=['get'], url_path='search-suggestions')
    def search_suggestions(self, request):
        q = (request.query_params.get('q') or '').strip()
        if not q:
            return Response([])
        suggestions = (
            Crop.objects.filter(name__istartswith=q)
            .order_by(Lower('name'))
            .values_list('name', flat=True)
            .distinct()[:10]
        )
        return Response(list(suggestions))

    @action(detail=True, methods=['get'])
    def details(self, request, pk=None):
        crop = self.get_object()
        serializer = CropDetailSerializer(crop)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='schedule')
    def schedule(self, request, pk=None):
        crop = self.get_object()
        planting_date_str = request.query_params.get('planting_date')

        if not planting_date_str:
            return Response(
                {'error': 'planting_date is required (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            from datetime import date, timedelta
            planting_date = date.fromisoformat(planting_date_str)
        except ValueError:
            return Response(
                {'error': 'Invalid date format'},
                status=status.HTTP_400_BAD_REQUEST
            )

        from datetime import date as today_date
        today = today_date.today()

        care_tasks = crop.care_tasks.all().order_by('recommended_dap')
        schedule = []

        for task in care_tasks:
            due_date = planting_date + timedelta(days=task.recommended_dap)
            days_remaining = (due_date - today).days

            if days_remaining < 0:
                reminder_status = 'overdue'
            elif days_remaining == 0:
                reminder_status = 'due_today'
            elif days_remaining <= 7:
                reminder_status = 'due_soon'
            else:
                reminder_status = 'upcoming'

            schedule.append({
                'task_id': task.id,
                'task_name': task.task_name,
                'description': task.description,
                'instructions': task.instructions,
                'recommended_dap': task.recommended_dap,
                'due_date': due_date.isoformat(),
                'days_remaining': days_remaining,
                'reminder_status': reminder_status,
                'frequency': task.frequency,
            })

        return Response({
            'crop_name': crop.name,
            'planting_date': planting_date_str,
            'total_tasks': len(schedule),
            'overdue': len([t for t in schedule if t['reminder_status'] == 'overdue']),
            'due_today': len([t for t in schedule if t['reminder_status'] == 'due_today']),
            'due_soon': len([t for t in schedule if t['reminder_status'] == 'due_soon']),
            'upcoming': len([t for t in schedule if t['reminder_status'] == 'upcoming']),
            'schedule': schedule,
        })

    @action(detail=True, methods=['get'], url_path='alerts')
    def alerts(self, request, pk=None):
        crop = self.get_object()
        alerts_list = []

        try:
            guide = crop.guides.first()
            if guide:
                if guide.pest_management:
                    alerts_list.append({
                        'type': 'pest',
                        'severity': 'warning',
                        'title': 'Pest Alert',
                        'message': guide.pest_management,
                        'icon': 'bug_report',
                    })
                if guide.disease_management:
                    alerts_list.append({
                        'type': 'disease',
                        'severity': 'error',
                        'title': 'Disease Prevention',
                        'message': guide.disease_management,
                        'icon': 'local_hospital',
                    })
        except Exception:
            pass

        alerts_list.append({
            'type': 'temperature',
            'severity': 'info',
            'title': 'Optimal Temperature',
            'message': (
                f'Keep temperature between {crop.optimal_temperature - 5}°C and '
                f'{crop.optimal_temperature + 5}°C. Current optimal: '
                f'{crop.optimal_temperature}°C'
            ),
            'icon': 'thermostat',
        })

        alerts_list.append({
            'type': 'water',
            'severity': 'info',
            'title': 'Watering Guide',
            'message': (
                f'This crop needs {crop.water_required_mm_per_week}mm of water per week. '
                'Overwatering causes root rot. '
                'Underwatering causes wilting.'
            ),
            'icon': 'water_drop',
        })

        return Response({
            'crop_name': crop.name,
            'total_alerts': len(alerts_list),
            'alerts': alerts_list,
        })

    @action(detail=False, methods=['get'])
    def by_season(self, request):
        season = request.query_params.get('season', None)
        if not season:
            return Response(
                {'error': 'season parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        crops = Crop.objects.filter(season__iexact=season.strip())
        page = self.paginate_queryset(crops)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(crops, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def recommendations(self, request):
        season = request.query_params.get('season', None)
        soil_type = request.query_params.get('soil_type', None)
        if not season:
            return Response(
                {'error': 'season parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        recommendations = CropRecommendation.objects.filter(
            recommended_season=season
        )
        if soil_type:
            recommendations = recommendations.filter(
                crop__soil_type__iexact=soil_type.strip()
            )
        recommendations = recommendations.order_by('-priority_score')
        page = self.paginate_queryset(recommendations)
        if page is not None:
            serializer = CropRecommendationSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = CropRecommendationSerializer(recommendations, many=True)
        return Response(serializer.data)


class CropGuideViewSet(viewsets.ModelViewSet):
    queryset = CropGuide.objects.select_related('crop').all()
    serializer_class = CropGuideSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['crop__name', 'sowing_instructions']
    ordering = ['-created_at']
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def for_crop(self, request):
        crop_id = request.query_params.get('crop_id', None)
        if not crop_id:
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            guide = CropGuide.objects.select_related('crop').get(
                crop_id=crop_id
            )
        except CropGuide.DoesNotExist:
            return Response(
                {'error': 'No guide found for this crop'},
                status=status.HTTP_404_NOT_FOUND
            )
        serializer = self.get_serializer(guide)
        return Response(serializer.data)


class CropGrowthStageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CropGrowthStage.objects.select_related('crop').all()
    serializer_class = CropGrowthStageSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter]
    ordering = ['crop', 'stage_number']
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def for_crop(self, request):
        crop_id = request.query_params.get('crop_id', None)
        if not crop_id:
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        stages = CropGrowthStage.objects.filter(
            crop_id=crop_id
        ).order_by('stage_number')
        page = self.paginate_queryset(stages)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(stages, many=True)
        return Response(serializer.data)


class CropCareTaskViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CropCareTask.objects.select_related('crop').all()
    serializer_class = CropCareTaskSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    search_fields = ['task_name', 'description']
    ordering = ['crop', 'recommended_dap']
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def for_crop(self, request):
        crop_id = request.query_params.get('crop_id', None)
        if not crop_id:
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        tasks = CropCareTask.objects.filter(
            crop_id=crop_id
        ).order_by('recommended_dap')
        page = self.paginate_queryset(tasks)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)


class CropRecommendationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CropRecommendation.objects.select_related('crop').all()
    serializer_class = CropRecommendationSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter]
    ordering = ['-priority_score']
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def by_season(self, request):
        season = request.query_params.get('season', None)
        if not season:
            return Response(
                {'error': 'season parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        recommendations = CropRecommendation.objects.filter(
            recommended_season=season
        ).order_by('-priority_score')
        page = self.paginate_queryset(recommendations)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(recommendations, many=True)
        return Response(serializer.data)
