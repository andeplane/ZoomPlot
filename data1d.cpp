#include "data1d.h"
#include <QLineSeries>
#include <limits>
Data1D::Data1D(QObject *parent) : QObject(parent)
{
    static_assert(std::numeric_limits<float>::is_iec559, "IEEE 754 required"); // -INFINITY and INFINITY supported
    m_xMinLimit = -std::numeric_limits<float>::infinity();
    m_xMaxLimit = -std::numeric_limits<float>::infinity();
}

float Data1D::xMin()
{
    updateLimits();
    return m_xMin;
}

float Data1D::xMax()
{
    updateLimits();
    return m_xMax;
}

float Data1D::yMin()
{
    updateLimits();
    return m_yMin;
}

float Data1D::yMax()
{
    updateLimits();
    return m_yMax;
}

void Data1D::updateLimits()
{
    if(!m_minMaxValuesDirty) return;
    if(m_points.size() == 0) {
        m_xMax = 0;
        m_xMin = 0;
        m_yMax = 0;
        m_yMin = 0;
        return;
    }

    // Assume that max/min values are in first value, test for all other values. This is guaranteed to be correct.
    qreal xMax = m_points.first().x();
    qreal xMin = m_points.first().x();
    qreal yMax = m_points.first().y();
    qreal yMin = m_points.first().y();

    for(QPointF &p : m_points) {
        xMax = std::max(p.x(), xMax);
        xMin = std::min(p.x(), xMin);
        yMax = std::max(p.y(), yMax);
        yMin = std::min(p.y(), yMin);
    }

    m_xMax = xMax;
    m_xMin = xMin;
    m_yMax = yMax;
    m_yMin = yMin;
    m_minMaxValuesDirty = false;

    emit xMaxChanged(m_xMax);
    emit xMinChanged(m_xMin);
    emit yMaxChanged(m_yMax);
    emit yMinChanged(m_yMin);
}

void Data1D::updateData(QAbstractSeries *series)
{
    if(series) {
        QXYSeries *xySeries = static_cast<QXYSeries*>(series);
        xySeries->replace(m_points);
    }
}

QVariantMap Data1D::subsets() const
{
    return m_subsets;
}

int Data1D::stride() const
{
    return m_stride;
}

Data1D *Data1D::parentData() const
{
    return m_parentData;
}

float Data1D::xMinLimit() const
{
    return m_xMinLimit;
}

float Data1D::xMaxLimit() const
{
    return m_xMaxLimit;
}

void Data1D::resampleSubset(Data1D &subset)
{
    subset.clear(true);
    // TODO: use binary search to find index of starting point based on subset's xMinLimit

    for(const QPointF &p : m_points) {
        subset.add(p, true);
    }
    subset.doEmitUpdated(false);
}

void Data1D::doEmitUpdated(bool children)
{
    if(m_dataDirty) {
        emit updated();
        m_dataDirty = false;
    }
    if(children) {
        for(QVariant &variant : m_subsets) {
            Data1D *data = variant.value<Data1D*>();
            data->doEmitUpdated(children);
        }
    }
}

void Data1D::addSubset(QString key, int stride, float xMinLimit, float xMaxLimit)
{
    Data1D *data = new Data1D(this);
    data->setStride(stride);
    data->setXMinLimit(xMinLimit);
    data->setXMaxLimit(xMaxLimit);
    m_subsets.insert(key, QVariant::fromValue(data));
    data->setParentData(this);
}

bool Data1D::enabled() const
{
    return m_enabled;
}

void Data1D::clear(bool silent)
{
    m_dataDirty = true;
    m_points.clear();
    m_strideCount = 0;
    for(QVariant &variant : m_subsets) {
        Data1D *data = variant.value<Data1D*>();
        data->clear(true);
    }

    if(!silent) doEmitUpdated(true);
}

void Data1D::add(float x, float y, bool silent)
{
    // TODO: Update x/y limits when adding points instead of marking values as dirty
    add(QPointF(x,y), silent);
}

void Data1D::add(const QPointF &point, bool silent)
{
    if(m_parentData) {
        if(++m_strideCount >= m_stride || m_points.size()==0) {
            // We should add this point and reset stride count if first point
            m_strideCount = 0;
        } else {
            m_points.replace(m_points.size()-1, point);
            m_dataDirty = true;
            if(!silent) {
                updateMinMaxWithPoint(point);
                doEmitUpdated(true);
            }
            return;
        }
    }

    m_points.append(point);
    m_minMaxValuesDirty = true;
    m_dataDirty = true;
    for(QVariant &variant : m_subsets) {
        Data1D *data = variant.value<Data1D*>();
        data->add(point, true);
    }

    if(!silent) {
        updateMinMaxWithPoint(point);
        doEmitUpdated(true);
    }
}

void Data1D::updateMinMaxWithPoint(const QPointF &point) {
    if(m_xMax < point.x()) {
        m_xMax = point.x();
        emit xMaxChanged(m_xMax);
    }

    if(m_xMin > point.x()) {
        m_xMin = point.x();
        emit xMinChanged(m_xMin);
    }

    if(m_yMax < point.y()) {
        m_yMax = point.y();
        emit yMaxChanged(m_yMax);
    }

    if(m_yMin > point.y()) {
        m_yMin = point.y();
        emit yMinChanged(m_yMin);
    }
}

void Data1D::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;
    emit enabledChanged(enabled);
}

void Data1D::setSubsets(QVariantMap subsets)
{
    if (m_subsets == subsets)
        return;

    m_subsets = subsets;
    emit subsetsChanged(subsets);
}

void Data1D::setStride(int stride)
{
    if (m_stride == stride)
        return;

    m_stride = stride;
    emit strideChanged(stride);
}

void Data1D::setParentData(Data1D *parentData)
{
    if (m_parentData == parentData)
        return;

    m_parentData = parentData;
    emit parentDataChanged(parentData);
}

void Data1D::setXMinLimit(float xMinLimit)
{
    if (m_xMinLimit == xMinLimit)
        return;

    m_xMinLimit = xMinLimit;
    if(m_parentData) {
        m_parentData->resampleSubset(*this);
    }
    emit xMinLimitChanged(xMinLimit);
}

void Data1D::setXMaxLimit(float xMaxLimit)
{
    if (m_xMaxLimit == xMaxLimit)
        return;

    m_xMaxLimit = xMaxLimit;
    if(m_parentData) {
        m_parentData->resampleSubset(*this);
    }
    emit xMaxLimitChanged(xMaxLimit);
}

