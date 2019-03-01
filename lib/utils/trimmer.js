export function calculateCornerResult(duration, value, width, fromRight) {
  // duration -> width
  // x -> value
  // x = duration * value / width

  // console.log( 'duration, value, width ');
  // console.log( duration, value, width );
  const val = Math.abs(value);
  const result = (duration) * val / width;
  return fromRight
    ? Math.floor((duration - result))
    : Math.floor(result);
}
export function calculatelimitTime ( duration, width, timeLimit, right) {
  const val = ( timeLimit * ( width ) ) / ( duration );
  return right
    ? Math.floor( ( width - val ) )
    : Math.floor( val  );
}

export function msToSec(ms) {
  return ms / 1000;
}

export function numberToHHMMSS({ number }) {

  return number;
}
