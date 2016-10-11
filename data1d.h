#ifndef DATA1D_H
#define DATA1D_H
#include <limits>
#include <QObject>
#include <QXYSeries>
using namespace QtCharts;
class Data1D : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(float xMinLimit READ xMinLimit WRITE setXMinLimit NOTIFY xMinLimitChanged)
    Q_PROPERTY(float xMaxLimit READ xMaxLimit WRITE setXMaxLimit NOTIFY xMaxLimitChanged)
    Q_PROPERTY(float xMin READ xMin NOTIFY xMinChanged)
    Q_PROPERTY(float xMax READ xMax NOTIFY xMaxChanged)
    Q_PROPERTY(float yMin READ yMin NOTIFY yMinChanged)
    Q_PROPERTY(float yMax READ yMax NOTIFY yMaxChanged)
    Q_PROPERTY(int stride READ stride WRITE setStride NOTIFY strideChanged)
    Q_PROPERTY(Data1D* parentData READ parentData WRITE setParentData NOTIFY parentDataChanged)
    Q_PROPERTY(QVariantMap subsets READ subsets WRITE setSubsets NOTIFY subsetsChanged)
public:
    explicit Data1D(QObject *parent = 0);
    Q_INVOKABLE void updateData(QAbstractSeries *series);
    Q_INVOKABLE void updateLimits();
    Q_INVOKABLE void add(float x, float y, bool silent = false);
    Q_INVOKABLE void addSubset(QString key, int stride, float xMinLimit = -std::numeric_limits<float>::infinity(), float xMaxLimit = std::numeric_limits<float>::infinity());
    void add(const QPointF &point, bool silent = false);
    void clear(bool silent = false);
    float xMin();
    float xMax();
    float yMin();
    float yMax();
    bool enabled() const;
    QVariantMap subsets() const;
    int stride() const;
    Data1D* parentData() const;
    float xMinLimit() const;
    float xMaxLimit() const;
    void updateSubset(Data1D &subset);
    void doEmitUpdated(bool children);

signals:
    void xMinChanged(float xMin);
    void xMaxChanged(float xMax);
    void yMinChanged(float yMin);
    void yMaxChanged(float yMax);
    void enabledChanged(bool enabled);
    void updated();
    void subsetsChanged(QVariantMap subsets);
    void strideChanged(int stride);
    void parentDataChanged(Data1D* parentData);
    void xMinLimitChanged(float xMinLimit);
    void xMaxLimitChanged(float xMaxLimit);

public slots:
    void setEnabled(bool enabled);
    void setSubsets(QVariantMap subsets);
    void setStride(int stride);
    void setParentData(Data1D* parentData);
    void setXMinLimit(float xMinLimit);
    void setXMaxLimit(float xMaxLimit);

private:
    Data1D* m_parentData = nullptr;
    QList<QPointF> m_points;
    QVariantMap m_subsets;
    float m_xMin = 0;
    float m_xMax = 0;
    float m_yMin = 0;
    float m_yMax = 0;
    bool m_dataDirty = false;
    bool m_minMaxValuesDirty = false;
    bool m_enabled = false;
    int m_stride = 1;
    int m_strideCount = 0;
    float m_xMinLimit;
    float m_xMaxLimit;
};

#endif // DATA1D_H
