import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import Papa from 'papaparse';
import _ from 'lodash';

const BusinessInsights = () => {
  const [data, setData] = useState({ products: [], geography: [], salesPeople: [] });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await window.fs.readFile('Business_Insights_Report.csv', { encoding: 'utf8' });
        const parsedData = Papa.parse(response, {
          header: true,
          dynamicTyping: true,
          skipEmptyLines: true
        });

        // Process data for different views
        const productData = _(parsedData.data)
          .groupBy('Product')
          .map((group, key) => ({
            name: key,
            sales: _.sumBy(group, 'Sales'),
            boxes: _.sumBy(group, 'Boxes')
          }))
          .value();

        const geoData = _(parsedData.data)
          .groupBy('Geography')
          .map((group, key) => ({
            name: key.trim(),
            sales: _.sumBy(group, 'Sales'),
            boxes: _.sumBy(group, 'Boxes')
          }))
          .value();

        const salesPeopleData = _(parsedData.data)
          .groupBy('Sales Person')
          .map((group, key) => ({
            name: key,
            sales: _.sumBy(group, 'Sales'),
            boxes: _.sumBy(group, 'Boxes')
          }))
          .orderBy(['sales'], ['desc'])
          .take(10)
          .value();

        setData({
          products: _.orderBy(productData, ['sales'], ['desc']),
          geography: _.orderBy(geoData, ['sales'], ['desc']),
          salesPeople: salesPeopleData
        });
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    };

    fetchData();
  }, []);

  const formatValue = (value) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  return (
    <div className="space-y-8 p-4">
      <Card>
        <CardHeader>
          <CardTitle>Top 10 Products by Sales</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.products.slice(0, 10)}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
                <YAxis tickFormatter={formatValue} />
                <Tooltip formatter={formatValue} />
                <Legend />
                <Bar dataKey="sales" fill="#8884d8" name="Sales" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Sales by Geography</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.geography}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis tickFormatter={formatValue} />
                <Tooltip formatter={formatValue} />
                <Legend />
                <Bar dataKey="sales" fill="#82ca9d" name="Sales" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Top 10 Sales People by Performance</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.salesPeople}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
                <YAxis tickFormatter={formatValue} />
                <Tooltip formatter={formatValue} />
                <Legend />
                <Bar dataKey="sales" fill="#ffc658" name="Sales" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default BusinessInsights;