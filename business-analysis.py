import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

class BusinessAnalyzer:
    def __init__(self, file_path):
        """Initialize the analyzer with the data file."""
        self.df = pd.read_csv(file_path)
        # Convert Date column to datetime
        self.df['Date'] = pd.to_datetime(self.df['Date'])
        # Clean up whitespace in string columns
        for col in ['Sales Person', 'Geography', 'Product']:
            self.df[col] = self.df[col].str.strip()

    def analyze_sales_by_category(self, category):
        """Analyze sales performance by any category (Product, Geography, or Sales Person)."""
        sales_analysis = self.df.groupby(category).agg({
            'Sales': ['sum', 'mean', 'count'],
            'Boxes': 'sum'
        }).round(2)
        
        sales_analysis.columns = ['Total Sales', 'Average Sale', 'Transaction Count', 'Total Boxes']
        sales_analysis = sales_analysis.sort_values('Total Sales', ascending=False)
        return sales_analysis

    def analyze_monthly_trends(self):
        """Analyze monthly sales trends."""
        monthly_sales = self.df.groupby(self.df['Date'].dt.to_period('M')).agg({
            'Sales': 'sum',
            'Boxes': 'sum',
            'Sales Person': 'nunique'
        })
        monthly_sales.columns = ['Total Sales', 'Total Boxes', 'Active Sales People']
        return monthly_sales

    def analyze_product_performance(self):
        """Detailed analysis of product performance."""
        product_metrics = self.df.groupby('Product').agg({
            'Sales': ['sum', 'mean', 'std'],
            'Boxes': 'sum'
        })
        
        product_metrics.columns = ['Total Sales', 'Average Sale', 'Sales Std Dev', 'Total Boxes']
        product_metrics['Sales per Box'] = product_metrics['Total Sales'] / product_metrics['Total Boxes']
        return product_metrics.sort_values('Total Sales', ascending=False)

    def analyze_sales_team_performance(self):
        """Analyze individual sales team performance."""
        sales_team = self.df.groupby('Sales Person').agg({
            'Sales': ['sum', 'mean', 'count', 'std'],
            'Boxes': 'sum'
        })
        
        sales_team.columns = ['Total Sales', 'Average Sale', 'Transaction Count', 'Sales Std Dev', 'Total Boxes']
        sales_team['Sales per Transaction'] = sales_team['Total Sales'] / sales_team['Transaction Count']
        return sales_team.sort_values('Total Sales', ascending=False)

    def analyze_geographic_performance(self):
        """Analyze sales performance by geography."""
        geo_analysis = self.df.groupby('Geography').agg({
            'Sales': ['sum', 'mean', 'count'],
            'Boxes': 'sum',
            'Sales Person': 'nunique'
        })
        
        geo_analysis.columns = ['Total Sales', 'Average Sale', 'Transaction Count', 
                              'Total Boxes', 'Number of Sales People']
        return geo_analysis.sort_values('Total Sales', ascending=False)

    def generate_visualizations(self):
        """Generate key visualizations for the analysis."""
        # Set up the style
        plt.style.use('seaborn')
        
        # Create a figure with multiple subplots
        fig = plt.figure(figsize=(20, 15))
        
        # 1. Top 10 Products by Sales
        plt.subplot(2, 2, 1)
        top_products = self.analyze_sales_by_category('Product')['Total Sales'].head(10)
        top_products.plot(kind='bar')
        plt.title('Top 10 Products by Sales')
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # 2. Sales by Geography
        plt.subplot(2, 2, 2)
        geo_sales = self.analyze_geographic_performance()['Total Sales']
        geo_sales.plot(kind='bar')
        plt.title('Sales by Geography')
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # 3. Monthly Sales Trend
        plt.subplot(2, 2, 3)
        monthly_trend = self.analyze_monthly_trends()['Total Sales']
        monthly_trend.plot(kind='line', marker='o')
        plt.title('Monthly Sales Trend')
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # 4. Sales Person Performance
        plt.subplot(2, 2, 4)
        top_sales_people = self.analyze_sales_team_performance()['Total Sales'].head(10)
        top_sales_people.plot(kind='bar')
        plt.title('Top 10 Sales People by Total Sales')
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        return fig

    def export_analysis(self, output_path):
        """Export all analyses to Excel with multiple sheets."""
        with pd.ExcelWriter(output_path) as writer:
            # Export each analysis to a separate sheet
            self.analyze_product_performance().to_excel(writer, sheet_name='Product Analysis')
            self.analyze_geographic_performance().to_excel(writer, sheet_name='Geographic Analysis')
            self.analyze_sales_team_performance().to_excel(writer, sheet_name='Sales Team Analysis')
            self.analyze_monthly_trends().to_excel(writer, sheet_name='Monthly Trends')

def main():
    # Initialize the analyzer
    analyzer = BusinessAnalyzer('Business_Insights_Report.csv')
    
    # Generate and save visualizations
    fig = analyzer.generate_visualizations()
    fig.savefig('business_insights_visualizations.png')
    
    # Export detailed analysis to Excel
    analyzer.export_analysis('business_insights_analysis.xlsx')
    
    # Print key insights
    print("\n=== Top 5 Products by Sales ===")
    print(analyzer.analyze_product_performance()['Total Sales'].head())
    
    print("\n=== Top 5 Sales People ===")
    print(analyzer.analyze_sales_team_performance()['Total Sales'].head())
    
    print("\n=== Geographic Performance ===")
    print(analyzer.analyze_geographic_performance()['Total Sales'])

if __name__ == "__main__":
    main()
