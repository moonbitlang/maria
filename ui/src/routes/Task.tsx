import { useParams } from "react-router";

export default function Task() {
  const params = useParams();
  console.log(params);
  return <div>Hello</div>;
}
