import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import Qt5Compat.GraphicalEffects

Item {
    id: root

    enum SongAndArtistTextPosition {
        AboveProgressBar,
        UnderProgressBar
    }

    // ── Kept for compatibility, mostly unused in new layout ────────────────
    property string albumPlaceholder:      plasmoid.configuration.albumPlaceholder
    property real   volumeStep:            plasmoid.configuration.volumeStep
    property bool   albumCoverBackground:  plasmoid.configuration.fullAlbumCoverAsBackground
    property bool   thumbnailVisible:      plasmoid.configuration.fullViewThumbnailVisible
    property bool   progressBarVisible:    plasmoid.configuration.fullViewProgressBarVisible
    property bool   volumeControlVisible:  plasmoid.configuration.fullViewVolumeControlVisible
    property bool   shuffleVisible:        false   // removed from layout
    property bool   playbackControlsVisible: plasmoid.configuration.fullViewPlaybackControlsVisible
    property bool   loopVisible:           false   // removed from layout
    property bool   playbackControlsFitWidth: plasmoid.configuration.fullViewPlaybackControlsFillWidth
    property bool   songTextVisible:       plasmoid.configuration.fullViewSongTextVisible
    property int    songTextAlignment:     plasmoid.configuration.fullViewSongTextAlignment
    property bool   songTextAboveProgressBar: plasmoid.configuration.fullViewSongTextPosition === Full.SongAndArtistTextPosition.AboveProgressBar
    property bool   fullAlbumCoverRounded: plasmoid.configuration.fullAlbumCoverRounded
    property int    albumCoverRadius:      plasmoid.configuration.fullAlbumCoverRadius

    // ── Fixed size ─────────────────────────────────────────────────────────
    readonly property int widgetWidth:  360
    readonly property int widgetHeight: 180

    Layout.minimumWidth:   widgetWidth
    Layout.maximumWidth:   widgetWidth
    Layout.preferredWidth: widgetWidth
    Layout.minimumHeight:  widgetHeight
    Layout.maximumHeight:  widgetHeight
    Layout.preferredHeight: widgetHeight

    // ── Palette ────────────────────────────────────────────────────────────
    readonly property color nothingBlack: "#0A0A0A"
    readonly property color nothingWhite: "#F5F5F5"
    readonly property color nothingGold:  "#D4AF37"

    // ── Outer dark border card ─────────────────────────────────────────────
    Rectangle {
        id: outerCard
        anchors.fill: parent
        color: "#18191C"
        radius: 24
    }

    // ── Inner content (art + overlays), inset 8px on all sides ────────────
    Item {
        id: innerCard
        anchors {
            fill:        parent
            margins:     8
        }

        // clip so art + gradient stay within rounded corners
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width:  innerCard.width
                height: innerCard.height
                radius: 18
            }
        }

        // ── Album art, full bleed ──────────────────────────────────────────
        ImageWithPlaceholder {
            id: albumArt
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            placeholderSource: root.albumPlaceholder
            imageSource: player.artUrl
        }

        // ── Left-to-right dark gradient overlay ───────────────────────────
        // Dark on the left where text lives, fades to transparent on the right
        LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, 0)
            end:   Qt.point(innerCard.width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "#F0151617" }   // near-opaque dark
                GradientStop { position: 0.65; color: "transparent" }
            }
        }

        // ── Bottom-up dark gradient so controls row is always readable ─────
        LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, innerCard.height)
            end:   Qt.point(0, innerCard.height * 0.45)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#CC151617" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Content: track info + bottom controls ─────────────────────────
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Kirigami.Theme.inherit: false
            Kirigami.Theme.textColor:      root.nothingWhite
            Kirigami.Theme.highlightColor: root.nothingGold

            // Spacer — pushes everything to the bottom half
            Item { Layout.fillHeight: true }

            // ── Track title ────────────────────────────────────────────────
            Text {
                visible: root.songTextVisible
                Layout.fillWidth: true
                Layout.leftMargin:   16
                Layout.rightMargin:  16
                Layout.bottomMargin: 2
                text:  player.title
                color: root.nothingWhite
                font.bold: true
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            // ── Artist — album ─────────────────────────────────────────────
            Text {
                visible: root.songTextVisible
                Layout.fillWidth: true
                Layout.leftMargin:   16
                Layout.rightMargin:  16
                Layout.bottomMargin: 10
                text:  player.artists.join(", ") + (player.album ? " — " + player.album : "")
                color: Qt.rgba(1, 1, 1, 0.75)
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            // ── Bottom row: progress bar + buttons ────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin:   16
                Layout.rightMargin:  16
                Layout.bottomMargin: 12
                spacing: 12

                // Progress bar — fills all remaining width
                TrackPositionSlider {
                    visible: root.progressBarVisible
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    songPosition: player.songPosition
                    songLength:   player.songLength
                    playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
                    enableChangePosition: player.canSeek
                    onRequireChangePosition: (position) => { player.setPosition(position) }
                    onRequireUpdatePosition: () => { player.updatePosition() }
                }

                // Play/pause pill
                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.playbackStatus === Mpris.PlaybackStatus.Playing
                             ? player.canPause : player.canPlay
                    Layout.alignment: Qt.AlignVCenter
                    size:       Kirigami.Units.iconSizes.small
                    source:     player.playbackStatus === Mpris.PlaybackStatus.Playing
                                ? "media-playback-pause" : "media-playback-start"
                    bgColor:    root.nothingGold
                    iconColorOverride: root.nothingBlack
                    extraWidth: size * 0.8
                    padding:    8
                    onClicked:  player.playPause()
                }

                // Previous circle
                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.canGoPrevious
                    Layout.alignment: Qt.AlignVCenter
                    size:    Kirigami.Units.iconSizes.small
                    source:  "media-skip-backward"
                    bgColor: "#2B2D32"
                    iconColorOverride: root.nothingWhite
                    padding: 9
                    onClicked: player.previous()
                }

                // Next circle
                CommandIcon {
                    visible: root.playbackControlsVisible
                    enabled: player.canGoNext
                    Layout.alignment: Qt.AlignVCenter
                    size:    Kirigami.Units.iconSizes.small
                    source:  "media-skip-forward"
                    bgColor: "#2B2D32"
                    iconColorOverride: root.nothingWhite
                    padding: 9
                    onClicked: player.next()
                }
            }
        }
    }
}
