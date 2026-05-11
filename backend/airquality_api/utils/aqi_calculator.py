"""
AQI (Air Quality Index) Calculation Module

Based on EPA AQI calculation methodology
https://www.airnow.gov/aqi/aqi-basics/
"""

class AQICalculator:
    """Calculate AQI based on pollutant concentrations."""
    
    # AQI breakpoints for different pollutants and categories
    AQI_BREAKPOINTS = {
        'good': (0, 50),
        'moderate': (51, 100),
        'unhealthy_sensitive': (101, 150),
        'unhealthy': (151, 200),
        'very_unhealthy': (201, 300),
        'hazardous': (301, 500),
    }

    # Pollutant-specific breakpoints (in μg/m³)
    CO_BREAKPOINTS = {
        'good': (0, 4.4),
        'moderate': (4.5, 9.4),
        'unhealthy_sensitive': (9.5, 12.4),
        'unhealthy': (12.5, 15.4),
        'very_unhealthy': (15.5, 30.4),
        'hazardous': (30.5, 50.4),
    }

    NO2_BREAKPOINTS = {
        'good': (0, 53),
        'moderate': (54, 100),
        'unhealthy_sensitive': (101, 360),
        'unhealthy': (361, 649),
        'very_unhealthy': (650, 1249),
        'hazardous': (1250, 2049),
    }

    BENZENE_BREAKPOINTS = {
        'good': (0, 5),
        'moderate': (5.1, 10),
        'unhealthy_sensitive': (10.1, 15),
        'unhealthy': (15.1, 20),
        'very_unhealthy': (20.1, 30),
        'hazardous': (30.1, 50),
    }

    PM25_BREAKPOINTS = {
        'good': (0, 12),
        'moderate': (12.1, 35.4),
        'unhealthy_sensitive': (35.5, 55.4),
        'unhealthy': (55.5, 150.4),
        'very_unhealthy': (150.5, 250.4),
        'hazardous': (250.5, 500),
    }

    CATEGORY_COLORS = {
        'good': '#009E3A',  # Green
        'moderate': '#FFFF00',  # Yellow
        'unhealthy_sensitive': '#FF7E00',  # Orange
        'unhealthy': '#FF0000',  # Red
        'very_unhealthy': '#8F3F97',  # Purple
        'hazardous': '#7E0023',  # Maroon
    }

    RECOMMENDATIONS = {
        'good': {
            'general': 'Air quality is satisfactory',
            'sensitive': 'You can engage in outdoor activities',
            'others': 'No air quality alerts',
        },
        'moderate': {
            'general': 'Air quality is acceptable',
            'sensitive': 'Unusually sensitive people should consider reducing outdoor activities',
            'others': 'Everyone can engage in outdoor activities',
        },
        'unhealthy_sensitive': {
            'general': 'Members of sensitive groups may experience health effects',
            'sensitive': 'You should reduce strong outdoor exertion; wear a mask if possible',
            'others': 'Outdoor activities are safe for most',
        },
        'unhealthy': {
            'general': 'Everyone may begin to experience health effects',
            'sensitive': 'Avoid outdoor activities; stay indoors with filtered air',
            'others': 'Reduce outdoor activities; wear a mask when outside',
        },
        'very_unhealthy': {
            'general': 'Health effects are more pronounced',
            'sensitive': 'Avoid all outdoor exposure; use HEPA filter indoors',
            'others': 'Avoid outdoor activities; wear N95 mask when necessary',
        },
        'hazardous': {
            'general': 'Health warnings of emergency conditions',
            'sensitive': 'Stay indoors with air purifier; avoid any outdoor activities',
            'others': 'Avoid outdoor activities; use air purifier indoors',
        },
    }

    @staticmethod
    def linear_interpolate(aqi_lo, aqi_hi, conc_lo, conc_hi, concentration):
        """Linear interpolation for AQI calculation."""
        return ((aqi_hi - aqi_lo) / (conc_hi - conc_lo)) * (concentration - conc_lo) + aqi_lo

    @classmethod
    def get_category_from_aqi(cls, aqi):
        """Get category name from AQI value."""
        for category, (low, high) in cls.AQI_BREAKPOINTS.items():
            if low <= aqi <= high:
                return category
        return 'hazardous'

    @classmethod
    def calculate_pollutant_aqi(cls, pollutant, concentration):
        """Calculate AQI for a specific pollutant."""
        if concentration is None:
            return None

        breakpoints = None
        if pollutant.lower() == 'co':
            breakpoints = cls.CO_BREAKPOINTS
        elif pollutant.lower() == 'no2':
            breakpoints = cls.NO2_BREAKPOINTS
        elif pollutant.lower() in ['benzene', 'c6h6']:
            breakpoints = cls.BENZENE_BREAKPOINTS
        elif pollutant.lower() in ['pm2.5', 'pm25']:
            breakpoints = cls.PM25_BREAKPOINTS
        else:
            return None

        # Find applicable breakpoint range
        for i, (category, (conc_lo, conc_hi)) in enumerate(breakpoints.items()):
            if conc_lo <= concentration <= conc_hi:
                aqi_range = list(cls.AQI_BREAKPOINTS.values())[i]
                aqi = cls.linear_interpolate(aqi_range[0], aqi_range[1], conc_lo, conc_hi, concentration)
                return round(aqi)

        # Out of range
        return 500

    @classmethod
    def calculate_overall_aqi(cls, co=None, no2=None, benzene=None, pm25=None):
        """Calculate overall AQI as the maximum of pollutant AQIs."""
        aqi_values = []

        if co is not None:
            aqi_values.append(cls.calculate_pollutant_aqi('co', co))
        if no2 is not None:
            aqi_values.append(cls.calculate_pollutant_aqi('no2', no2))
        if benzene is not None:
            aqi_values.append(cls.calculate_pollutant_aqi('benzene', benzene))
        if pm25 is not None:
            aqi_values.append(cls.calculate_pollutant_aqi('pm25', pm25))

        # Remove None values
        aqi_values = [v for v in aqi_values if v is not None]

        if not aqi_values:
            return None, 'unknown'

        overall_aqi = max(aqi_values)
        category = cls.get_category_from_aqi(overall_aqi)

        return overall_aqi, category

    @classmethod
    def get_color_for_aqi(cls, aqi):
        """Get color code for AQI value."""
        category = cls.get_category_from_aqi(aqi)
        return cls.CATEGORY_COLORS.get(category, '#FFFFFF')

    @classmethod
    def get_recommendations(cls, aqi, age_group='adult', health_conditions=None):
        """Get health recommendations based on AQI and user profile."""
        category = cls.get_category_from_aqi(aqi)
        recommendations = cls.RECOMMENDATIONS.get(category, {})

        # Determine user group
        if age_group in ['child', 'senior'] or health_conditions:
            rec_type = 'sensitive'
        else:
            rec_type = 'others'

        return {
            'category': category,
            'aqi': aqi,
            'general': recommendations.get('general', ''),
            'personal': recommendations.get(rec_type, ''),
            'color': cls.get_color_for_aqi(aqi),
        }
