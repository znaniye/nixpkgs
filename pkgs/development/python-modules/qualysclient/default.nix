{
  lib,
  buildPythonPackage,
  setuptools,
  certifi,
  charset-normalizer,
  fetchFromGitHub,
  idna,
  lxml,
  pytest-mock,
  pytestCheckHook,
  pythonOlder,
  requests,
  responses,
  urllib3,
}:

buildPythonPackage rec {
  pname = "qualysclient";
  version = "0.0.4.8.3";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "woodtechie1428";
    repo = "qualysclient";
    tag = "v${version}";
    hash = "sha256-+SZICysgSC4XeXC9CCl6Yxb47V9c1eMp7KcpH8J7kK0=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "version=__version__," 'version="${version}",'
  '';

  build-system = [ setuptools ];

  dependencies = [
    certifi
    charset-normalizer
    idna
    lxml
    requests
    urllib3
  ];

  nativeCheckInputs = [
    pytest-mock
    pytestCheckHook
    responses
  ];

  pythonImportsCheck = [ "qualysclient" ];

  meta = with lib; {
    description = "Python SDK for interacting with the Qualys API";
    homepage = "https://qualysclient.readthedocs.io/";
    changelog = "https://github.com/woodtechie1428/qualysclient/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
