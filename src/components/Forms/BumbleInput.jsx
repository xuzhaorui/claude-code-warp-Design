export default function BumbleInput({ label, value, onChange, type = 'text', className = '' }) {
  return (
    <div className={`relative mb-6 ${className}`}>
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder=" "
        className="bumble-input w-full"
      />
      <label className="bumble-label">{label}</label>
    </div>
  );
}
