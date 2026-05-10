import { useRef, useEffect } from 'react';

export default function BumbleInput({
  label, value, onChange, type = 'text',
  error = false, errorMsg = '',
  className = ''
}) {
  const groupRef = useRef(null);

  useEffect(() => {
    if (!error || !groupRef.current) return;
    groupRef.current.classList.add('shake');
    const timer = setTimeout(() => groupRef.current?.classList.remove('shake'), 300);
    return () => clearTimeout(timer);
  }, [error]);

  return (
    <div ref={groupRef} className={`bumble-input-group relative mb-6 ${className}`}>
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder=" "
        className={`bumble-input w-full${error ? ' error' : ''}`}
      />
      <label className="bumble-label">{label}</label>
      <div className="bumble-input-underline" />
      {errorMsg && <p className="bumble-error-msg">{errorMsg}</p>}
    </div>
  );
}
