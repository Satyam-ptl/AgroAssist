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
        seasons = (
            Crop.objects.exclude(season__isnull=True)
            .exclude(season__exact='')
            .values_list('season', flat=True)
            .distinct()
        )
        return Response(sorted(seasons, key=lambda s: s.lower()))

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
