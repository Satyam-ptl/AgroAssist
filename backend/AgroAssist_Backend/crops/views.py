# Import ViewSet classes from Django REST Framework for API endpoints
from rest_framework import viewsets, filters, status  # Import API tools
from rest_framework.decorators import action  # Decorator for custom actions
from rest_framework.response import Response  # API response class
from rest_framework.pagination import PageNumberPagination  # For pagination
from rest_framework.permissions import IsAuthenticated, IsAdminUser  # Permission classes

# Import models and serializers
from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation
from .serializers import (CropSerializer, CropGuideSerializer, CropGrowthStageSerializer,
                         CropCareTaskSerializer, CropRecommendationSerializer, CropDetailSerializer)


# CUSTOM PAGINATION - For limiting number of results returned
class StandardResultsSetPagination(PageNumberPagination):
    # PageNumberPagination = Show results in pages (like page 1, page 2, etc.)
    
    # page_size = How many results per page
    page_size = 20  # Show 20 results per page
    
    # page_size_query_param = URL parameter to change page size (e.g., ?page_size=50)
    page_size_query_param = 'page_size'
    
    # max_page_size = Maximum results per page (prevent huge requests)
    max_page_size = 100  # Never give more than 100 results per page


# VIEWSET 1: CropViewSet - API endpoints for Crop model
class CropViewSet(viewsets.ModelViewSet):
    # ModelViewSet = Automatically provides CRUD operations (Create, Read, Update, Delete)
    
    # queryset = What data to work with
    queryset = Crop.objects.all()  # Get all crops from database
    
    # serializer_class = How to convert models to/from JSON
    serializer_class = CropSerializer  # Use CropSerializer for JSON conversion
    
    # pagination_class = How to paginate results (show 20 per page)
    pagination_class = StandardResultsSetPagination  # Use pagination defined above
    
    # filter_backends = Search/filter capability
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Allow search and ordering
    
    # search_fields = Which fields can be searched
    search_fields = ['name', 'description', 'season', 'category', 'crop_type']  # Search by key crop fields
    
    # ordering_fields = Which fields can be sorted
    ordering_fields = ['name', 'growth_duration_days', 'created_at']  # Can sort by these
    
    # ordering = Default sort order
    ordering = ['-created_at']  # Show newest crops first by default
    
    # permission_classes = Require authentication
    permission_classes = [IsAuthenticated]
    
    def get_permissions(self):
        """Only admins can create/edit/delete crops; all authenticated users can read."""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        queryset = Crop.objects.all()

        season = self.request.query_params.get('season')
        soil_type = self.request.query_params.get('soil_type')
        category = self.request.query_params.get('category')
        crop_type = self.request.query_params.get('crop_type')
        state = self.request.query_params.get('state')

        if state:
            state = state.strip()

        if season:
            queryset = queryset.filter(season=season)
        if soil_type:
            queryset = queryset.filter(soil_type=soil_type)
        if category:
            queryset = queryset.filter(category=category)
        if crop_type:
            queryset = queryset.filter(crop_type=crop_type)
        if state:
            queryset = queryset.filter(description__icontains=state)

        return queryset
    
    # ACTION ENDPOINT: Details with related data
    @action(detail=True, methods=['get'])  # Custom action for GET request at /crops/1/details/
    def details(self, request, pk=None):
        # pk = Primary key (ID) of the crop
        
        # Get the specific crop
        crop = self.get_object()  # Get crop by ID
        
        # Use detailed serializer that includes all related data
        serializer = CropDetailSerializer(crop)  # Serialize with all nested data
        
        # Return JSON response
        return Response(serializer.data)  # Send serialized data as response
    
    # ACTION ENDPOINT: Get crops for a specific season
    @action(detail=False, methods=['get'])  # Custom action for GET request at /crops/by_season/
    def by_season(self, request):
        # request.query_params = URL parameters (?season=Kharif)
        
        # Get season from URL parameter
        season = request.query_params.get('season', None)  # Get ?season= parameter
        
        if not season:  # If no season provided
            return Response(
                {'error': 'season parameter is required'},  # Error message
                status=status.HTTP_400_BAD_REQUEST  # HTTP 400 = Bad Request
            )
        
        # Filter crops by season
        crops = Crop.objects.filter(season=season)  # Get crops for this season
        
        # Paginate results
        page = self.paginate_queryset(crops)  # Split into pages
        
        if page is not None:  # If pagination worked
            serializer = self.get_serializer(page, many=True)  # Serialize page
            return self.get_paginated_response(serializer.data)  # Return paginated response
        
        # If no pagination
        serializer = self.get_serializer(crops, many=True)  # Serialize all
        return Response(serializer.data)  # Return all results
    
    # ACTION ENDPOINT: Get crop recommendations for a season
    @action(detail=False, methods=['get'])  # Custom action at /crops/recommendations/
    def recommendations(self, request):
        # Get season from URL parameter
        season = request.query_params.get('season', None)  # ?season=Kharif
        soil_type = request.query_params.get('soil_type', None)  # ?soil_type=Loamy
        state = request.query_params.get('state', None)  # ?state=Maharashtra

        if state:
            state = state.strip()
        
        if not season:  # If no season
            return Response(
                {'error': 'season parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get recommendations for this season (and optional soil)
        recommendations = CropRecommendation.objects.filter(
            recommended_season=season
        )

        if soil_type:
            recommendations = recommendations.filter(crop__soil_type=soil_type)
        if state:
            recommendations = recommendations.filter(crop__description__icontains=state)

        recommendations = recommendations.order_by('-priority_score')
        
        # Paginate
        page = self.paginate_queryset(recommendations)
        
        if page is not None:
            serializer = CropRecommendationSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = CropRecommendationSerializer(recommendations, many=True)
        return Response(serializer.data)


# VIEWSET 2: CropGuideViewSet - API endpoints for Crop Guides
class CropGuideViewSet(viewsets.ModelViewSet):
    # ModelViewSet for CRUD operations on guides
    
    queryset = CropGuide.objects.all()  # All guides
    serializer_class = CropGuideSerializer  # Use CropGuideSerializer
    pagination_class = StandardResultsSetPagination  # Paginate results
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Search/sort
    
    # search_fields = Search by crop name or in guide text
    search_fields = ['crop__name', 'sowing_instructions']  # Search in these fields
    
    # ordering = Default sort (newest first)
    ordering = ['-created_at']
    
    # ACTION: Get guide for a specific crop
    @action(detail=False, methods=['get'])  # GET at /guides/for_crop/
    def for_crop(self, request):
        # Get crop ID from URL parameter
        crop_id = request.query_params.get('crop_id', None)  # ?crop_id=1
        
        if not crop_id:  # If no crop ID
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get guide for this crop
        try:
            guide = CropGuide.objects.get(crop_id=crop_id)  # Get by crop ID
        except CropGuide.DoesNotExist:  # If not found
            return Response(
                {'error': 'No guide found for this crop'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = self.get_serializer(guide)  # Serialize
        return Response(serializer.data)  # Return


# VIEWSET 3: CropGrowthStageViewSet - API endpoints for growth stages
class CropGrowthStageViewSet(viewsets.ReadOnlyModelViewSet):
    # ReadOnlyModelViewSet = Can only read (GET), not create/edit
    
    queryset = CropGrowthStage.objects.all()  # All growth stages
    serializer_class = CropGrowthStageSerializer  # Use serializer
    pagination_class = StandardResultsSetPagination  # Paginate
    filter_backends = [filters.OrderingFilter]  # Can sort
    ordering = ['crop', 'stage_number']  # Sort by crop then stage number
    
    # ACTION: Get stages for a specific crop
    @action(detail=False, methods=['get'])  # GET at /growth-stages/for_crop/
    def for_crop(self, request):
        # Get crop ID from parameter
        crop_id = request.query_params.get('crop_id', None)
        
        if not crop_id:
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get all stages for this crop in order
        stages = CropGrowthStage.objects.filter(crop_id=crop_id).order_by('stage_number')
        
        # Paginate
        page = self.paginate_queryset(stages)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(stages, many=True)
        return Response(serializer.data)


# VIEWSET 4: CropCareTaskViewSet - API endpoints for care tasks
class CropCareTaskViewSet(viewsets.ReadOnlyModelViewSet):
    # ReadOnlyModelViewSet = Read-only (GET only)
    
    queryset = CropCareTask.objects.all()  # All care tasks
    serializer_class = CropCareTaskSerializer  # Use serializer
    pagination_class = StandardResultsSetPagination  # Paginate
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]  # Search/sort
    search_fields = ['task_name', 'description']  # Search by these
    ordering = ['crop', 'recommended_dap']  # Sort by crop, then by days
    
    # ACTION: Get tasks for a specific crop
    @action(detail=False, methods=['get'])  # GET at /care-tasks/for_crop/
    def for_crop(self, request):
        # Get crop ID
        crop_id = request.query_params.get('crop_id', None)
        
        if not crop_id:
            return Response(
                {'error': 'crop_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get all tasks for this crop in order
        tasks = CropCareTask.objects.filter(crop_id=crop_id).order_by('recommended_dap')
        
        # Paginate
        page = self.paginate_queryset(tasks)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)


# VIEWSET 5: CropRecommendationViewSet - API for recommendations
class CropRecommendationViewSet(viewsets.ReadOnlyModelViewSet):
    # ReadOnlyModelViewSet = Read-only
    
    queryset = CropRecommendation.objects.all()  # All recommendations
    serializer_class = CropRecommendationSerializer  # Use serializer
    pagination_class = StandardResultsSetPagination  # Paginate
    filter_backends = [filters.OrderingFilter]  # Can sort
    ordering = ['-priority_score']  # Most important first
    
    # ACTION: Get recommendations for a season
    @action(detail=False, methods=['get'])  # GET at /recommendations/by_season/
    def by_season(self, request):
        # Get season parameter
        season = request.query_params.get('season', None)
        
        if not season:
            return Response(
                {'error': 'season parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get recommendations for this season
        recommendations = CropRecommendation.objects.filter(
            recommended_season=season
        ).order_by('-priority_score')  # Sort by priority
        
        # Paginate
        page = self.paginate_queryset(recommendations)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(recommendations, many=True)
        return Response(serializer.data)
