# Import Django's database model class that all database tables inherit from  
from django.db import models

# MODEL 1: Crop - Main crop information stored in database
class Crop(models.Model):
    # CharField = Text field with max length (like name, string data)
    name = models.CharField(max_length=100)  # Name of crop like "Rice", "Wheat", "Cotton"

    CATEGORY_CHOICES = [
        ('Cereal', 'Cereal'),
        ('Pulse', 'Pulse'),
        ('Oilseed', 'Oilseed'),
        ('Vegetable', 'Vegetable'),
        ('Fruit', 'Fruit'),
        ('Fodder', 'Fodder'),
        ('Other', 'Other'),
    ]
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='Other')

    CROP_TYPE_CHOICES = [
        ('Field', 'Field Crop'),
        ('Horticulture', 'Horticulture'),
        ('Plantation', 'Plantation'),
        ('Greenhouse', 'Greenhouse'),
        ('Other', 'Other'),
    ]
    crop_type = models.CharField(max_length=20, choices=CROP_TYPE_CHOICES, default='Field')
    
    # TextField = Long text field without max length limit (for descriptions)
    description = models.TextField(blank=True)  # Description of what the crop is and its uses
    
    # CharField with choices = Dropdown field (farmer selects from options)
    SEASON_CHOICES = [
        ('Kharif', 'Kharif (Monsoon)'),  # Monsoon season crops
        ('Rabi', 'Rabi (Winter)'),  # Winter season crops
        ('Summer', 'Summer'),  # Summer season crops
    ]
    season = models.CharField(max_length=20, choices=SEASON_CHOICES, default='Kharif')  # Which season to grow

    states = models.CharField(
        max_length=500,
        blank=True,
        default='',
        help_text='Comma-separated states where this crop grows. e.g. Maharashtra,Punjab,Gujarat'
    )
    
    # CharField with choices = Dropdown for soil type
    SOIL_CHOICES = [
        ('Clay', 'Clay Soil'),  # Heavy, moisture-retaining soil
        ('Sandy', 'Sandy Soil'),  # Light, fast-draining soil
        ('Loamy', 'Loamy Soil'),  # Balanced, ideal soil
        ('Mixed', 'Mixed Soil'),  # Mixture of soil types
    ]
    soil_type = models.CharField(max_length=20, choices=SOIL_CHOICES)  # Type of soil needed
    
    # IntegerField = Whole numbers only (no decimals)
    growth_duration_days = models.IntegerField()  # Days from planting to harvest (e.g., 120 days)
    
    # FloatField = Decimal numbers allowed (like 25.5 degrees)
    optimal_temperature = models.FloatField()  # Best temperature for growing (e.g., 25.5 degrees Celsius)
    optimal_humidity = models.FloatField()  # Best humidity percentage (e.g., 60%)
    optimal_soil_moisture = models.FloatField()  # Best soil moisture level (e.g., 45%)
    
    # FloatField = Water amount needed per week
    water_required_mm_per_week = models.FloatField(default=25)  # Water neededeach week in millimeters
    
    # CharField = Text field
    fertilizer_required = models.CharField(max_length=200, default='NPK')  # e.g., "NPK 10-26-26"
    
    # DecimalField = Money/precise decimal numbers (max_digits=10, decimal_places=2)
    expected_yield_per_hectare = models.DecimalField(max_digits=10, decimal_places=2, default=0)  # Harvest amount
    
    # DateTimeField = Auto-set when record is created (auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)  # When this record was added to database
    
    # DateTimeField = Auto-update every time record is edited (auto_now=True)
    updated_at = models.DateTimeField(auto_now=True)  # When this record was last edited
    
    # Meta class = Settings/configuration for this model
    class Meta:
        # verbose_name = How to display model name in admin/list views
        verbose_name = "Crop"  # Singular name
        verbose_name_plural = "Crops"  # Plural name
        # ordering = Default sort order when fetching all crops
        ordering = ['-created_at']  # Newest crops first (- means descending)
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['category']),
            models.Index(fields=['crop_type']),
            models.Index(fields=['season']),
            models.Index(fields=['states']),
            models.Index(fields=['soil_type']),
        ]
    
    # __str__ = What text shows when printing this object
    def __str__(self):
        # Returns "Rice (Kharif)" format when displaying in admin
        return f"{self.name} ({self.category}/{self.crop_type})"


# MODEL 2: CropGuide - Step-by-step growing instructions for each crop
class CropGuide(models.Model):
    # ForeignKey = Link to another model (many CropGuides can link to one Crop)
    # on_delete=models.CASCADE = Delete guides if crop is deleted
    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='guides')  # Which crop this guide is for
    
    # TextField = Long text for detailed instructions (no character limit)
    sowing_instructions = models.TextField()  # How and when to plant seeds in detail
    
    watering_schedule = models.TextField()  # How often and how much to water
    
    # IntegerField = Whole numbers for specific day intervals
    watering_days_interval = models.IntegerField(default=7)  # Water every X days (e.g., every 7 days)
    
    fertilizer_schedule = models.TextField()  # When to add fertilizer and how much
    
    disease_management = models.TextField()  # How to prevent and treat diseases
    
    pest_management = models.TextField()  # How to prevent and manage pests
    
    harvesting_instructions = models.TextField()  # How to know when and how to harvest
    
    storage_instructions = models.TextField(blank=True)  # How to store crop after harvesting
    
    # DateTimeField = Auto-set when record is created
    created_at = models.DateTimeField(auto_now_add=True)
    
    # DateTimeField = Auto-update when record is modified
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Crop Guide"
        verbose_name_plural = "Crop Guides"
    
    def __str__(self):
        # Shows "Rice Guide" format
        return f"{self.crop.name} Guide"


# MODEL 3: CropGrowthStage - Different growth phases of a crop over time
class CropGrowthStage(models.Model):
    # Link to Crop model (each crop has multiple growth stages)
    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='growth_stages')  # Which crop
    
    # CharField = Text field for stage names
    stage_name = models.CharField(max_length=100)  # e.g., "Germination", "Flowering", "Maturity"
    
    # IntegerField = Days for this stage duration (e.g., 20 days for germination)
    duration_days = models.IntegerField()  # How many days this growth stage lasts
    
    # IntegerField = Sequence number (1st, 2nd, 3rd stage, etc.)
    stage_number = models.IntegerField()  # Order of appearance (1, 2, 3...)
    
    # FloatField = Optimal conditions during this growth phase
    optimal_temperature = models.FloatField()  # Best temperature for this stage
    optimal_humidity = models.FloatField()  # Best humidity for this stage
    optimal_soil_moisture = models.FloatField()  # Best soil moisture for this stage
    
    # TextField = Descriptions and instructions specific to this stage
    description = models.TextField(blank=True)  # What farmer should expect to see
    care_instructions = models.TextField(blank=True)  # Special care needed during this stage
    
    # DateTimeField = Auto-set on creation
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        # ordering = Sort by crop and then by stage number (earliest stage first)
        ordering = ['crop', 'stage_number']
        verbose_name = "Growth Stage"
        verbose_name_plural = "Growth Stages"
    
    def __str__(self):
        # Shows "Rice - Stage 1: Germination" format
        return f"{self.crop.name} - Stage {self.stage_number}: {self.stage_name}"


# MODEL 4: CropCareTask - Specific tasks farmers must do at certain times during crop growth
class CropCareTask(models.Model):
    # Link to Crop model (each crop has multiple care tasks)
    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='care_tasks')  # Which crop
    
    # CharField = Task name/title
    task_name = models.CharField(max_length=100)  # e.g., "Apply fertilizer", "Check for pests"
    
    # TextField = Detailed description of what to do
    description = models.TextField()  # What exactly needs to be done and why
    
    # IntegerField = Days after planting when to perform this task
    recommended_dap = models.IntegerField()  # DAP = Days After Planting (e.g., 30 DAP for 1st fertilizer)
    
    # CharField = How often to repeat this task
    frequency = models.CharField(max_length=50, default='Once')  # "Once", "Weekly", "Bi-weekly", etc.
    
    # TextField = Step-by-step how to perform this task
    instructions = models.TextField()  # Detailed instructions for farmers to follow
    
    # DateTimeField = Auto-set on creation
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        # ordering = Sort by crop and then by days after planting (tasks in correct order)
        ordering = ['crop', 'recommended_dap']
        verbose_name = "Care Task"
        verbose_name_plural = "Care Tasks"
    
    def __str__(self):
        # Shows "Rice - Apply Fertilizer (30 DAP)" format
        return f"{self.crop.name} - {self.task_name} ({self.recommended_dap} DAP)"


# MODEL 5: CropRecommendation - Suggest which crops to plant based on season/conditions
class CropRecommendation(models.Model):
    # Link to Crop model (each crop can have multiple recommendations)
    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='recommendations')  # Which crop to recommend
    
    # CharField with choices = Season when this crop is recommended
    SEASON_CHOICES = [
        ('Kharif', 'Kharif'),  # Monsoon season
        ('Rabi', 'Rabi'),  # Winter season
        ('Summer', 'Summer'),  # Summer season
    ]
    recommended_season = models.CharField(max_length=20, choices=SEASON_CHOICES)  # When to plant
    
    # TextField = Why this crop is good for farmers
    recommendation_reason = models.TextField()  # Explanation for farmers (e.g., "High market demand")
    
    # IntegerField = Priority score (1-10, higher = more recommended)
    priority_score = models.IntegerField(default=5)  # Importance score for ranking recommendations
    
    # DateTimeField = Auto-set on creation
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Crop Recommendation"
        verbose_name_plural = "Crop Recommendations"
        ordering = ['-priority_score']  # Show highest priority first (- = descending)
    
    def __str__(self):
        # Shows "Recommend Rice in Kharif" format
        return f"Recommend {self.crop.name} in {self.recommended_season}"
