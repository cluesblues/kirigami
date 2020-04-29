/*
 *  Copyright 2020 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

#pragma once

#include <QObject>
#include <QColor>
#include <QImage>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QPointer>
#include <QQuickWindow>
#include <QFuture>

class QTimer;

struct ImageData {
    struct colorStat {
        QList<QRgb> colors;
        QRgb centroid = 0;
        qreal ratio = 0;
    };

    struct colorSet {
        QColor average;
        QColor text;
        QColor background;
        QColor highlight;
    };

    QList<QRgb> m_samples;
    QList<colorStat> m_clusters;
    QVariantList m_palette;

    QColor m_dominant;
    QColor m_average;
    QColor m_highlight;

    
    QColor m_suggestedContrast;
    QColor m_mostSaturated;
    QColor m_closestToBlack;
    QColor m_closestToWhite;
};

class ImageColors : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QVariantList palette READ palette NOTIFY paletteChanged)

    Q_PROPERTY(QColor average READ average NOTIFY averageChanged)
    Q_PROPERTY(QColor suggestedContrast READ suggestedContrast NOTIFY suggestedContrastChanged)
    Q_PROPERTY(QColor mostSaturated READ mostSaturated NOTIFY mostSaturatedChanged)
    Q_PROPERTY(QColor closestToWhite READ closestToWhite NOTIFY closestToWhiteChanged)
    Q_PROPERTY(QColor closestToBlack READ closestToBlack NOTIFY closestToBlackChanged)

public:
    explicit ImageColors(QObject* parent = nullptr);
    ~ImageColors();

    void setSource(const QVariant &source);
    QVariant source() const;

    void setSourceImage(const QImage &image);
    QImage sourceImage() const;

    void setSourceItem(QQuickItem *source);
    QQuickItem *sourceItem() const;

    Q_INVOKABLE void update();

    QVariantList palette() const;
    QColor average() const;
    QColor suggestedContrast() const;
    QColor mostSaturated() const;
    QColor closestToWhite() const;
    QColor closestToBlack() const;

Q_SIGNALS:
    void sourceChanged();
    void paletteChanged();
    void averageChanged();
    void suggestedContrastChanged();
    void mostSaturatedChanged();
    void closestToBlackChanged();
    void closestToWhiteChanged();

private:
    static inline void positionColor(QRgb rgb, QList<ImageData::colorStat> &clusters);
    static ImageData generatePalette(const QImage &sourceImage);

    // Arbitrary number that seems to work well
    static const int s_minimumSquareDistance = 32000;
    QPointer<QQuickWindow> m_window;
    QVariant m_source;
    QPointer<QQuickItem> m_sourceItem;
    QSharedPointer<QQuickItemGrabResult> m_grabResult;
    QImage m_sourceImage;


    QTimer *m_imageSyncTimer;

    QFutureWatcher<ImageData> *m_futureImageData = nullptr;
    ImageData m_imageData;
};
