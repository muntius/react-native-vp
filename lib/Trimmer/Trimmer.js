import React, { Component } from 'react';
import PropTypes from 'prop-types';
import {
  View,
  Image,
  NativeModules,
  Platform,
  StyleSheet,
  Dimensions,
  PanResponder,
  Text,
  Animated
} from 'react-native';

import { calculateCornerResult, calculatelimitTime } from '../utils';

import { ProcessingManager } from 'react-native-vp';

const { width } = Dimensions.get( 'window' );
const videoTimeLimit = 10

const styles = StyleSheet.create( {
  container: {
    height: 60,
    overflow: 'hidden',
  },
  container1: {
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
    overflow: 'hidden',
    backgroundColor: 'rgba(32,64,104, 0.7)', borderRadius: 25,
   
  },
  ImageView: {
    width: '100%',
    borderRadius: 5,
  },
  column: {
    flexDirection: 'column',
    width: '100%',
    borderRadius: 5,
    overflow: 'hidden',
  },
  columLeft: {
    flexDirection: 'column',
    alignItems: 'flex-end',
  },
  imageItem: {
    flex: 1,
    width: 30,
    height: 30,
    justifyContent: 'center',

    resizeMode: 'cover'
  },
  corners: {
    position: 'absolute',
    paddingHorizontal: 5,
    top: -30,
    height: 30,
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  rightCorner: {
    position: 'absolute',
    justifyContent: 'flex-end',
    overflow: 'hidden',
  },
  leftCorner: {
    left: 0,
    justifyContent: 'flex-end',
  },
  bgBlack: {
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    width,
    height: 30,
  },
  bgTrans: {
    height: 20,
    width: 20
  },
  cornerItem: {
    position: 'absolute',
    backgroundColor: '#E7CFC3',
    width: 10,
    height: 30,
    borderRadius: 5,
    borderColor: 'rgba(32,64,104, 1)',
    borderWidth: 1,
    overflow: 'hidden',
  },
  cropViewTextWrapperCenter: {
    alignItems: 'center',
    alignSelf: 'center',
    borderRadius: 5,
    height: 15,
    overflow: 'hidden'
  },
  textTimer: {
    color: 'white',
    textAlign: 'center',
    fontSize: 10,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    width: '100%',
  }
} );
export class Trimmer extends Component {
  static propTypes = {
    source: PropTypes.string.isRequired,
    onChangeLeft: PropTypes.func,
    onChangeRight: PropTypes.func,
    currentTime: PropTypes.func,
    duration: PropTypes.number.isRequired,
  };
  static defaultProps = {
    onChange: () => null,
    onChangeLeft: () => null,
    onChangRight: () => null,
    currentTime: () => 0,
    duration: () => 0,
    

  };

  constructor ( props ) {
    super( props );
    this.state = {
      images: [],
      duration: -1,
      leftCorner: new Animated.Value( 0 ),
      rightCorner: new Animated.Value( 0 ),
      layoutWidth: width * 0.6,
      showTime: false,
      startTime: 0,
      endTime: 1
    };
    this.leftResponder = null;
    this.rigthResponder = null;
    this.timer = null;
    this._startTime = 0;
    this._endTime = 0;
    this._currentTime = 0;
    this._handleRightCornerMove = this._handleRightCornerMove.bind( this );
    this._handleLeftCornerMove = this._handleLeftCornerMove.bind( this );
    this._retriveInfo = this._retriveInfo.bind( this );
    this._retrivePreviewImages = this._retrivePreviewImages.bind( this );
    this._handleRightCornerRelease = this._handleRightCornerRelease.bind( this );
    this._handleLeftCornerRelease = this._handleLeftCornerRelease.bind( this );
  }

  componentWillMount () {
    this.state.leftCorner.addListener( ( { value } ) => {
      this._leftCornerPos = value
    } );
    this.state.rightCorner.addListener( ( { value } ) => {
      this._rightCornerPos = value
    } );

    this.leftResponder = PanResponder.create( {
      onMoveShouldSetPanResponder: ( e, gestureState ) => Math.abs( gestureState.dx ) > 0,
      onMoveShouldSetPanResponderCapture: ( e, gestureState ) => Math.abs( gestureState.dx ) > 0,
      onPanResponderGrant: ( e, gestureState ) => {
        if ( !this.state.showTime ) {
          clearTimeout( this.timer )
          this.setState( { showTime: true } )
        }
      },
      onPanResponderMove: this._handleLeftCornerMove,
      onPanResponderRelease: this._handleLeftCornerRelease
    } );
    this.rightResponder = PanResponder.create( {
      onMoveShouldSetPanResponder: ( e, gestureState ) => Math.abs( gestureState.dx ) > 0,
      onMoveShouldSetPanResponderCapture: ( e, gestureState ) => Math.abs( gestureState.dx ) > 0,
      onPanResponderGrant: ( e, gestureState ) => {
        if ( !this.state.showTime ) {
          clearTimeout( this.timer )
          this.setState( { showTime: true } )
        }
      },
      onPanResponderMove: this._handleRightCornerMove,
      onPanResponderRelease: this._handleRightCornerRelease
    } );
    const { source = '' } = this.props;
    if ( !source.trim() ) {
      throw new Error( 'source should be valid string' );
      
    }
    this._retriveInfo(this.props.source,this.props.duration);
  }

  componentWillReceiveProps ( nextProps ) {
    if ( nextProps.source !== this.props.source ) {
      this._retriveInfo(nextProps.source,nextProps.duration);
    }
  }

  componentWillUnmount () {
    this.state.leftCorner.removeAllListeners();
    this.state.rightCorner.removeAllListeners();
    clearTimeout( this.timer );
  }

  hideTime () {
    this.setState( {
      showTime: false
    } );
  }

  _handleLeftCornerRelease () {
    this._leftCornerPos = this._leftCornerPos || 0
    this._rightCornerPos = this._rightCornerPos || 0

    if ( this._leftCornerPos < 0 ) {
      this._leftCornerPos = 0
      this._startTime = 0
      this.limitTime = 0;
      this.state.leftCorner.setOffset(this.limitTime );
      this.state.leftCorner.setValue( 0 );
      this._callOnChangeLeft()
    }
    if ( this._startTime >= this._endTime ) {
      this._startTime = this._endTime - 1
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._startTime, false );
      this.state.leftCorner.setOffset(this.limitTime );
      this.state.leftCorner.setValue( 0 );
      this._callOnChangeRight()
    }
    if ( this._endTime - this._startTime > videoTimeLimit ) {
      this._endTime = this._startTime + videoTimeLimit
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._endTime, true );
      this.state.rightCorner.setOffset( - this.limitTime  );
      this.state.rightCorner.setValue( 0 );
      this._callOnChangeRight()
    } 
      this.state.leftCorner.setOffset( this._leftCornerPos );
      this.state.leftCorner.setValue( 0 );
   
    this.props.currentTime( {
      currentTime: this._startTime
    } );
    this.timer = setTimeout( this.hideTime.bind( this ), 1500 );
  }

  _handleRightCornerRelease () {
    this._leftCornerPos = this._leftCornerPos || 0
    this._rightCornerPos = this._rightCornerPos || 0


    if ( this._rightCornerPos > 0 ) {
      this._rightCornerPos = 0
      this._endTime = this.state.duration
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._endTime, true );
      this.state.rightCorner.setOffset(-this.limitTime );
      this.state.rightCorner.setValue( 0 );
      this._callOnChangeRight()
    }
    if ( this._rightCornerPos < -this.state.layoutWidth ) {
      this._rightCornerPos = 0
      this._endTime = this._startTime + 1
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._endTime, true );
      this.state.rightCorner.setOffset(-this.limitTime );
      this.state.rightCorner.setValue( 0 );
      this._callOnChangeRight()
    }
    if ( this._endTime <= this._startTime ) {      
      this._endTime = this._startTime + 1
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._endTime, true );
      this.state.rightCorner.setOffset(-this.limitTime  );
      this.state.rightCorner.setValue( 0 );
      this._callOnChangeRight()
    }

      if ( this._endTime - this._startTime > videoTimeLimit ) {
      this._startTime = this._endTime - videoTimeLimit
      this.limitTime = calculatelimitTime( this.state.duration, this.state.layoutWidth-10, this._startTime, false );

      this.state.leftCorner.setOffset( this.limitTime  );
      this.state.leftCorner.setValue( 0 );
      this._callOnChangeLeft()
    }

      this.state.rightCorner.setOffset( this._rightCornerPos );
      this.state.rightCorner.setValue( 0 );
    this.props.currentTime( {
      currentTime: this._endTime
    } );
    this.timer = setTimeout( this.hideTime.bind( this ), 1500 );

  }
  _handleRightCornerMove ( e, gestureState ) {
    const { duration, layoutWidth } = this.state;
    this._leftCornerPos = this._leftCornerPos || 0
    this._rightCornerPos = this._rightCornerPos || 0
    const leftPos = this._leftCornerPos;
    const rightPos = layoutWidth - 10 + this._rightCornerPos;
    const moveLeft = gestureState.dx < 0;
    this._endTime = calculateCornerResult( duration, this._rightCornerPos, layoutWidth - 10, true );
    if ( ( rightPos - leftPos <= 0 && moveLeft ) || rightPos >  layoutWidth - 10) {
      gestureState.dx = 0
      return;
    }

    this._callOnChangeRight();
    Animated.event( [
      null, { dx: this.state.rightCorner }
    ] )( e, gestureState );
  }

  _handleLeftCornerMove ( e, gestureState ) {
    const { duration, layoutWidth } = this.state;
    this._rightCornerPos = this._rightCornerPos || 0
    this._leftCornerPos = this._leftCornerPos || 0
    let leftPos = this._leftCornerPos;
    let rightPos = layoutWidth -10 - Math.abs( this._rightCornerPos );
    let moveRight = gestureState.dx > 0;
    // if ( ( rightPos - leftPos <= 5 && moveRight ) || leftPos < 0 ) {
    this._startTime = calculateCornerResult( duration, this._leftCornerPos, layoutWidth - 10 );
    if ( ( rightPos - leftPos <= 0 && moveRight ) || leftPos < 0  ) {
      gestureState.dx = 0
      return;
    }
    this._callOnChangeLeft();

    Animated.event( [
      null,
      { dx: this.state.leftCorner }
    ] )( e, gestureState );
  }

  _callOnChangeLeft () {
    this.setState({startTime: this._startTime })
    this.props.onChangeLeft( {
      startTime: this._startTime
    } );
  }
  _callOnCurrentTime () {
    this.props.currentTime( {
      currentTime: this._currentTime
    } );
  }

  _callOnChangeRight () {
    this.setState({endTime: this._endTime })
    this.props.onChangeRight( {
      endTime: this._endTime
    } );
  }
  _retriveInfo ( source, duration ) {   
    this._startTime = 0;
    this.state.leftCorner.setOffset( 0 );
    this.state.leftCorner.setValue( 0 );
    if ( duration === 0 ) {
      duration = 1
    }
    if ( duration > videoTimeLimit ) {
      this._endTime = videoTimeLimit;
      this.limitTime = calculatelimitTime( duration, this.state.layoutWidth-10, this._endTime, true );
    } else {
      this._endTime = duration;
      this.limitTime = calculatelimitTime( duration, this.state.layoutWidth-10, this._endTime, true );
    }
      this.state.rightCorner.setOffset( - this.limitTime );
      this.state.rightCorner.setValue( 0 );
    this.setState( () => ( {
          duration
        } ) );
    this._retrivePreviewImages(source,Math.floor(duration));
    this._callOnChangeLeft();
    this._callOnChangeRight();
   
  }
  _retrivePreviewImages ( source, duration ) {
    Platform.OS === 'ios' ? this._retrivePreviewImagesIOS( source, duration ) : this._retrivePreviewImagesAndroid(source)
    }
  _retrivePreviewImagesIOS ( source, duration ) {
    const maximumSize = { width: 50, height: 50 };
      ProcessingManager.getPreviewForSecond( source, duration, maximumSize, "JPEG")
        .then( ( data ) => {
          if ( data.length > 0 ) {
            this.setState( { images: data } );
          }
        } )
      // } )
      .catch( ( e ) => console.error( e ) );
  }
    
    _retrivePreviewImagesAndroid () {
    const { RNTrimmerManager: TrimmerManager } = NativeModules;
    TrimmerManager
      .getPreviewImages( this.props.source )
      .then( ( { images } ) => {
        this.setState( { images } );
      } )
      .catch( ( e ) => console.error( e ) );
  }
  renderLeftSection () {
    const { leftCorner, layoutWidth } = this.state;
    let left = -layoutWidth - ( width * 0.2 ) + 10
    return (
      <Animated.View
        style={ [ styles.container, styles.leftCorner, {
          left,
          transform: [ {
            translateX: leftCorner,
          } ]
        } ] }
        { ...this.leftResponder.panHandlers }
      >
        <View style={ { borderRadius: 5,} }>
          <View style={[styles.bgBlack, {right: 5}] } />
          <View style={[styles.cornerItem, {right: 0}]} />
        </View>
      </Animated.View>
    );
  }

  renderRightSection () {
    const { rightCorner, layoutWidth } = this.state;
    let left = layoutWidth + ( width * 0.2 ) - 5
    return (
      <Animated.View
        style={ [ styles.container, styles.rightCorner, { left}, {
          transform: [ {
            translateX: rightCorner
          } ]
        } ] }
        { ...this.rightResponder.panHandlers }
      >
        <View style={ {
          borderRadius: 5,
        } }>
          <View style={ [styles.bgBlack,{left: 5}] } />
          <View style={ [ styles.cornerItem, {left: 0,}] } />
        </View>
      </Animated.View>
    )
  }


  renderTextSection () {
    return (
      <View >
        <Text style={ styles.textTimer } >{ this.numberToHHMMSS( this._startTime ) } : { this.numberToHHMMSS( this._endTime ) }</Text>
      </View>
    )
  }

  numberToHHMMSS ( number ) {
    let sec_num = number;
    let hours = Math.floor( sec_num / 3600 );
    let minutes = Math.floor( ( sec_num - ( hours * 3600 ) ) / 60 );
    let seconds = ( sec_num - ( hours * 3600 ) - ( minutes * 60 ) );

    if ( hours < 10 ) { hours = "0" + hours; }
    if ( minutes < 10 ) { minutes = "0" + minutes; }
    if ( seconds < 10 ) { seconds = "0" + seconds; }
    return ( hours + ':' + minutes + ':' + Math.round(seconds) );
  }

  render () {
    const { images, showTime } = this.state;
    return (
      <View style={ styles.container }>
         <View  style= {styles.cropViewTextWrapperCenter} >
        { showTime && this.renderTextSection() }
        </View>
        <View onLayout={ ( { nativeEvent } ) => {
              this.setState( {
                layoutWidth: nativeEvent.layout.width - 5
              } );
        } }
          style={ styles.container1 }>
            <View
              style={ {
                marginHorizontal: 5,
                flexDirection: 'row',
              flex: 1,
                top: 5,
                borderRadius: 5,
                overflow: 'hidden',
                height: 30,
                justifyContent: 'center'
              } }>
            { images.map( ( uri, index ) => (
              <Image
                key={ `preview-source-${ uri }-${ index }` }
                source={ { uri } }
                style={ styles.imageItem }
              />
            ) ) }
            <View style={ styles.corners }>
              { this.renderLeftSection() }
              { this.renderRightSection() }
            </View>
            </View>
          
          </View>
    </View>
    );
  }
}